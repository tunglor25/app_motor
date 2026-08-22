import CoreBluetooth
import Foundation

/// Native CoreBluetooth client for the ESP32-S3 dashboard scanner. Mirrors the
/// state machine of the Kotlin source's ble/EcuBleManager.kt -- see that file for
/// the reasoning behind each defensive choice (scan-by-service-only, forced
/// re-discovery after every connect, per-characteristic subscribe isolation, no
/// fake default values, 3s auto-reconnect).
///
/// Two adaptations from the Android version, called out explicitly:
/// - CoreBluetooth's `setNotifyValue(true, for:)` handles the CCCD descriptor
///   write internally and serializes it, so there is no manual one-at-a-time
///   descriptor-write queue here (Android needs one because BluetoothGatt only
///   allows a single in-flight GATT operation per connection).
/// - CoreBluetooth's service discovery is two-phase (discoverServices then
///   discoverCharacteristics per service), unlike Android's single-phase
///   discoverServices(); there is also no public equivalent of Android's
///   BluetoothGatt.refresh() cache-invalidation hack -- discoverServices() is
///   simply called fresh on every connection instead.
///
/// Every failure path below (scan timeout, connect timeout, discover timeout,
/// service missing, disconnect) ends in either idle or a scheduled retry, matching
/// the Android manager's guarantee that a stuck-forever error state must not happen.
@MainActor
final class EcuBleManager: NSObject, ObservableObject {
    @Published private(set) var connectionState: BleConnectionState = .idle
    @Published private(set) var ecuReading = EcuReading()

    private var centralManager: CBCentralManager!
    private var activePeripheral: CBPeripheral?
    private var controlCharacteristic: CBCharacteristic?

    private var scanning = false
    private var connecting = false

    private var scanTimeoutWork: DispatchWorkItem?
    private var connectTimeoutWork: DispatchWorkItem?
    private var discoverTimeoutWork: DispatchWorkItem?
    private var retryWork: DispatchWorkItem?

    private let scanTimeout: TimeInterval = 15
    private let connectTimeout: TimeInterval = 10
    private let discoverTimeout: TimeInterval = 5
    private let retryDelay: TimeInterval = 3

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func isBluetoothEnabled() -> Bool {
        centralManager.state == .poweredOn
    }

    func startScanAndConnect() {
        // Guards against a re-entrant scan: iOS silently ignores a second
        // scanForPeripherals() call while one is active, and the ESP32 not
        // advertising during a brownout means didDiscover can legitimately
        // never fire, so this must not be re-entrant.
        guard !scanning, !connecting else { return }
        guard centralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth khong kha dung")
            return
        }
        scanning = true
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: [BleUuids.service], options: nil)

        scanTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.scanning else { return }
            self.stopScanQuietly()
            self.connectionState = .error("Khong tim thay ECU, dang thu lai...")
            self.scheduleScanRetry()
        }
        scanTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout, execute: work)
    }

    func disconnect() {
        retryWork?.cancel()
        scanTimeoutWork?.cancel()
        connectTimeoutWork?.cancel()
        discoverTimeoutWork?.cancel()
        stopScanQuietly()
        connecting = false
        if let peripheral = activePeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        activePeripheral = nil
        controlCharacteristic = nil
        connectionState = .idle
    }

    // Troll button -- writes cmdC4 to trigger the ESP32's bomb-countdown beep
    // sequence. Unrelated to any real ECU data, just a joke.
    func triggerC4Mode() { writeControlCommand(BleUuids.cmdC4) }

    /// Clears the real MIL/trouble codes on the ECU via Mode 04 -- a genuine
    /// diagnostic command, not a joke, use after the bike has been repaired.
    func clearDtc() { writeControlCommand(BleUuids.cmdClearDtc) }

    /// Dong bo cau hinh bat/tat am thanh coi & loa xuong ESP32 qua lenh cmdSetSound ('S')
    func syncSoundSettings(settings: AppSettings) {
        guard let peripheral = activePeripheral, let characteristic = controlCharacteristic else { return }
        let payload = Data([BleUuids.cmdSetSound, settings.soundBitmask])
        peripheral.writeValue(payload, for: characteristic, type: .withResponse)
    }

    private func writeControlCommand(_ cmd: UInt8) {
        guard let peripheral = activePeripheral, let characteristic = controlCharacteristic else { return }
        let payload = Data([cmd])
        peripheral.writeValue(payload, for: characteristic, type: .withResponse)
    }

    private func stopScanQuietly() {
        scanTimeoutWork?.cancel()
        if scanning { centralManager.stopScan() }
        scanning = false
    }

    private func scheduleScanRetry() {
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.startScanAndConnect() }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay, execute: work)
    }

    private func connectToDevice(_ device: CBPeripheral) {
        guard !connecting else { return }
        connecting = true
        activePeripheral = device
        device.delegate = self
        connectionState = .connecting
        centralManager.connect(device, options: nil)

        connectTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.connecting else { return }
            self.connecting = false
            self.connectionState = .error("Connect timeout, dang thu lai...")
            self.centralManager.cancelPeripheralConnection(device)
            self.scheduleReconnect()
        }
        connectTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + connectTimeout, execute: work)
    }

    private func scheduleReconnect() {
        guard let device = activePeripheral else {
            // No known device yet (failed before ever finding one) -- fall back
            // to a fresh scan instead of a targeted reconnect.
            scheduleScanRetry()
            return
        }
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.connectToDevice(device) }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay, execute: work)
    }

    private func handleCharacteristicUpdate(_ uuid: CBUUID, _ data: Data) {
        switch uuid {
        case BleUuids.charTelemetry:
            parseTelemetryPacket(data)
        case BleUuids.charDTC:
            parseDtcPacket(data)
        default:
            break
        }
    }

    /// 12-byte packed telemetry: [RPM_H,RPM_L,Speed,ECT,TPS,Volt_H,Volt_L,IAT,
    /// O2_H,O2_L,StatusFlags,CRC]. Volt/O2 are integers scaled by 100 (e.g.
    /// 1245 = 12.45V). Mirrors sendTelemetryPacket() in the firmware .ino --
    /// keep both in sync if this format ever changes.
    private func parseTelemetryPacket(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 12 else { return }
        var crc: UInt8 = 0
        for i in 0..<11 { crc ^= bytes[i] }
        guard crc == bytes[11] else { return } // corrupted/noisy packet, discard

        var reading = ecuReading
        reading.rpm = (Int(bytes[0]) << 8) | Int(bytes[1])
        reading.speed = Int(bytes[2])
        reading.ect = Int(Int8(bitPattern: bytes[3]))
        reading.tps = Int(bytes[4])
        let voltScaled = (Int(bytes[5]) << 8) | Int(bytes[6])
        reading.battery = Float(voltScaled) / 100.0
        reading.iat = Int(Int8(bitPattern: bytes[7]))
        let o2Scaled = (Int(bytes[8]) << 8) | Int(bytes[9])
        reading.o2Voltage = Float(o2Scaled) / 100.0
        reading.ecuConnected = (bytes[10] & 0x01) != 0
        ecuReading = reading
    }

    /// Comma-separated DTC codes (e.g. "P0135,P0115"), empty string = no codes.
    private func parseDtcPacket(_ data: Data) {
        let text = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var reading = ecuReading
        reading.dtcCodes = text.isEmpty ? [] : text.split(separator: ",").map(String.init)
        ecuReading = reading
    }
}

extension EcuBleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // No-op: isBluetoothEnabled() is queried on demand; power-off mid-connection
        // surfaces via didDisconnectPeripheral/didFailToConnect like any other drop.
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard scanning else { return }
        stopScanQuietly()
        connectToDevice(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectTimeoutWork?.cancel()

        discoverTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.connecting else { return }
            self.connecting = false
            self.connectionState = .error("Timeout do tim dich vu, dang thu lai...")
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.scheduleReconnect()
        }
        discoverTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + discoverTimeout, execute: work)

        // Always force a fresh service/characteristic table on every connection --
        // no fatalError/skip if the firmware is missing a characteristic, matches
        // the per-characteristic isolation in the Kotlin source.
        peripheral.discoverServices([BleUuids.service])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connecting = false
        connectTimeoutWork?.cancel()
        discoverTimeoutWork?.cancel()
        connectionState = .error("Connect that bai, dang thu lai...")
        scheduleReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connecting = false
        connectTimeoutWork?.cancel()
        discoverTimeoutWork?.cancel()
        controlCharacteristic = nil
        connectionState = .disconnected
        scheduleReconnect()
    }
}

extension EcuBleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoverTimeoutWork?.cancel()
        guard let service = peripheral.services?.first(where: { $0.uuid == BleUuids.service }) else {
            connecting = false
            connectionState = .error("Khong tim thay service tren thiet bi, dang thu lai...")
            centralManager.cancelPeripheralConnection(peripheral)
            scheduleReconnect()
            return
        }
        peripheral.discoverCharacteristics(nil, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        connecting = false
        connectionState = .connected

        guard let characteristics = service.characteristics else { return }
        for uuid in BleUuids.allCharacteristics {
            // Firmware may not have this characteristic yet -- skip it, never crash;
            // a missing characteristic must not block the others.
            guard let characteristic = characteristics.first(where: { $0.uuid == uuid }) else { continue }
            peripheral.setNotifyValue(true, for: characteristic)
        }
        controlCharacteristic = characteristics.first(where: { $0.uuid == BleUuids.charControl })
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        handleCharacteristicUpdate(characteristic.uuid, data)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // No-op: CoreBluetooth handles the CCCD descriptor write internally.
    }
}
