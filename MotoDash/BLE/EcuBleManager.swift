import CoreBluetooth
import Foundation

@MainActor
final class EcuBleManager: NSObject, ObservableObject {
    @Published private(set) var connectionState: BleConnectionState = .idle
    @Published private(set) var ecuReading = EcuReading()
    @Published private(set) var logs: [AppLogEntry] = []
    @Published private(set) var logRawPackets: Bool = false

    private var centralManager: CBCentralManager!
    private var activePeripheral: CBPeripheral?
    private var controlCharacteristic: CBCharacteristic?
    private var audioDataCharacteristic: CBCharacteristic?

    private var scanning = false
    private var connecting = false
    private var pendingScanOnPowerOn = true

    private var scanTimeoutWork: DispatchWorkItem?
    private var connectTimeoutWork: DispatchWorkItem?
    private var discoverTimeoutWork: DispatchWorkItem?
    private var retryWork: DispatchWorkItem?

    private let scanTimeout: TimeInterval = 10
    private let connectTimeout: TimeInterval = 10
    private let discoverTimeout: TimeInterval = 6
    private let retryDelay: TimeInterval = 3

    private var logIdCounter: Int64 = 0
    private var packetCounter: Int64 = 0
    private var lastPacketUptime: TimeInterval = 0
    private var smoothedHz: Float = 0
    private var lastSampledPacketLogUptime: TimeInterval = 0
    private var lastLoggedEcuConn: Bool?
    private var lastLoggedSideStand: Bool?
    private var lastSyncedMask: Int = -1
    private var lastSyncedVolIdx: Int = -1

    private var writeContinuation: CheckedContinuation<Bool, Never>?
    private var writeTimeoutWork: DispatchWorkItem?

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        addLog(.ble, "Khởi tạo hệ thống BLE MotoDash iOS", "Service UUID: \(BleUuids.service.uuidString)")
    }

    func addLog(_ category: LogCategory, _ title: String, _ detail: String = "", isError: Bool = false) {
        logIdCounter += 1
        let ts = Self.timeFormatter.string(from: Date())
        let entry = AppLogEntry(
            id: logIdCounter,
            timestamp: ts,
            category: category,
            title: title,
            detail: detail,
            isError: isError
        )
        logs.insert(entry, at: 0)
        if logs.count > 400 {
            logs.removeLast(logs.count - 400)
        }
    }

    func clearLogs() {
        logs.removeAll()
        addLog(.ble, "Đã xóa bộ nhớ đệm nhật ký")
    }

    func setLogRawPackets(_ enabled: Bool) {
        logRawPackets = enabled
        addLog(.packet, enabled ? "Bật ghi log mọi gói tin HEX (Live Stream)" : "Tắt ghi log gói tin liên tục")
    }

    func isBluetoothEnabled() -> Bool {
        centralManager.state == .poweredOn
    }

    func startScanAndConnect() {
        retryWork?.cancel()
        guard !scanning, !connecting else { return }
        guard centralManager.state == .poweredOn else {
            pendingScanOnPowerOn = true
            connectionState = .scanning
            addLog(.ble, "Đang khởi động Bluetooth iOS...", "Tự động quét ngay khi Bluetooth sẵn sàng")
            return
        }
        pendingScanOnPowerOn = false

        let alreadyConnected = centralManager.retrieveConnectedPeripherals(withServices: [BleUuids.service])
        if let existing = alreadyConnected.first {
            addLog(.ble, "Tìm thấy mạch đang kết nối sẵn: \(existing.name ?? BleUuids.deviceName)")
            connectToDevice(existing)
            return
        }

        scanning = true
        connectionState = .scanning
        addLog(.ble, "Đang quét tìm mạch \(BleUuids.deviceName)...", "Quét đa kênh (Tên thiết bị + Service UUID)")
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        scanTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.scanning else { return }
            self.stopScanQuietly()
            self.connectionState = .error("Khong tim thay ECU, dang thu lai...")
            self.addLog(.ble, "Quét BLE hết thời gian (10s)", "Chưa tìm thấy Honda_AB2025_Dash, tự thử lại sau 3s...", isError: true)
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
        audioDataCharacteristic = nil
        lastSyncedMask = -1
        lastSyncedVolIdx = -1
        connectionState = .idle
        addLog(.ble, "Người dùng ngắt kết nối BLE")
    }

    func triggerC4Mode() {
        addLog(.audio, "Gửi lệnh Troll C4 (0x43)", "Kích hoạt còi + loa I2S MAX98357A")
        writeControlCommand(BleUuids.cmdC4)
    }

    func clearDtc() {
        addLog(.kline, "Gửi lệnh xóa mã lỗi DTC (Mode 04 - 0x44)", "Đang yêu cầu ECU xóa đèn báo lỗi MIL...")
        writeControlCommand(BleUuids.cmdClearDtc)
    }

    func syncSoundSettings(settings: AppSettings) {
        let mask = Int(settings.soundBitmask)
        let vol = settings.speakerVolIdx
        if mask != lastSyncedMask {
            lastSyncedMask = mask
            addLog(.audio, "Đồng bộ cấu hình âm thanh xuống ESP32", String(format: "Bitmask: 0x%02X", mask))
            writeControlPayload(Data([BleUuids.cmdSetSound, settings.soundBitmask]))
            if vol != lastSyncedVolIdx {
                lastSyncedVolIdx = vol
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                    self?.writeControlPayload(Data([BleUuids.cmdSetVolume, UInt8(vol & 0xFF)]))
                }
            }
        } else if vol != lastSyncedVolIdx {
            lastSyncedVolIdx = vol
            writeControlPayload(Data([BleUuids.cmdSetVolume, UInt8(vol & 0xFF)]))
        }
    }

    func useDefaultBootMusic() {
        addLog(.audio, "Chuyển về nhạc chào mặc định (0x58)", "Đọc từ bộ nhớ PROGMEM trên ESP32-S3")
        writeControlCommand(BleUuids.cmdAudioUseDefault)
    }

    func selectBootTrack(trackId: Int, label: String) {
        addLog(.audio, "Chọn & Phát thử nhạc khởi động: \(label)", "CMD 0x42 ('B') · Track ID=\(trackId) (24kHz/16kHz Lossless)")
        writeControlPayload(Data([BleUuids.cmdSelectBootTrack, UInt8(trackId & 0xFF)]))
    }

    func selectWarnTrack(trackId: Int, label: String) {
        addLog(.audio, "Chọn & Phát thử cảnh báo quên tắt khóa: \(label)", "CMD 0x57 ('W') · Track ID=\(trackId) + Còi HXD")
        writeControlPayload(Data([BleUuids.cmdSelectWarnTrack, UInt8(trackId & 0xFF)]))
    }

    func setSpeakerVolume(volIdx: Int, label: String) {
        lastSyncedVolIdx = volIdx
        addLog(.audio, "Đổi âm lượng loa MAX98357A: \(label)", "CMD 0x56 ('V') · VolIdx=\(volIdx)")
        writeControlPayload(Data([BleUuids.cmdSetVolume, UInt8(volIdx & 0xFF)]))
    }

    func uploadBootMusic(data: Data, onProgress: @escaping (Float) -> Void) async -> Result<Void, Error> {
        guard let peripheral = activePeripheral else {
            return .failure(NSError(domain: "BLE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chưa kết nối BLE"]))
        }
        guard let ctrlChar = controlCharacteristic else {
            return .failure(NSError(domain: "BLE", code: 2, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy CONTROL characteristic"]))
        }
        guard let audioChar = audioDataCharacteristic else {
            return .failure(NSError(domain: "BLE", code: 3, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy AUDIO_DATA characteristic"]))
        }

        let total = data.count
        let maxWriteLen = max(20, min(peripheral.maximumWriteValueLength(for: .withResponse), 500))
        addLog(.audio, "Bắt đầu upload nhạc WAV tùy chỉnh", "Kích thước: \(total) bytes · Chunk: \(maxWriteLen)B")

        let sizePayload = Data([
            BleUuids.cmdAudioStart,
            UInt8(total & 0xFF),
            UInt8((total >> 8) & 0xFF),
            UInt8((total >> 16) & 0xFF),
            UInt8((total >> 24) & 0xFF)
        ])
        guard await writeAndAwait(peripheral: peripheral, characteristic: ctrlChar, payload: sizePayload) else {
            addLog(.audio, "Lỗi gửi lệnh CMD_AUDIO_START", isError: true)
            return .failure(NSError(domain: "BLE", code: 4, userInfo: [NSLocalizedDescriptionKey: "Không gửi được lệnh bắt đầu upload"]))
        }

        var offset = 0
        while offset < total {
            let end = min(offset + maxWriteLen, total)
            let chunk = data.subdata(in: offset..<end)
            guard await writeAndAwait(peripheral: peripheral, characteristic: audioChar, payload: chunk) else {
                addLog(.audio, "Lỗi truyền dữ liệu âm thanh", "Tại byte \(offset) / \(total)", isError: true)
                return .failure(NSError(domain: "BLE", code: 5, userInfo: [NSLocalizedDescriptionKey: "Lỗi truyền dữ liệu tại byte \(offset)/\(total)"]))
            }
            offset = end
            onProgress(Float(offset) / Float(total))
        }

        guard await writeAndAwait(peripheral: peripheral, characteristic: ctrlChar, payload: Data([BleUuids.cmdAudioEnd])) else {
            addLog(.audio, "Lỗi gửi lệnh CMD_AUDIO_END", isError: true)
            return .failure(NSError(domain: "BLE", code: 6, userInfo: [NSLocalizedDescriptionKey: "Không gửi được lệnh kết thúc upload"]))
        }
        addLog(.audio, "Hoàn tất upload nhạc chào ✓", "Đã lưu \(total) bytes vào FFat Flash (/boot.wav)")
        return .success(())
    }

    private func writeAndAwait(peripheral: CBPeripheral, characteristic: CBCharacteristic, payload: Data) async -> Bool {
        if writeContinuation != nil { return false }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.writeContinuation = continuation
            let work = DispatchWorkItem { [weak self] in
                guard let self, let cont = self.writeContinuation else { return }
                self.writeContinuation = nil
                cont.resume(returning: false)
            }
            self.writeTimeoutWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: work)
            peripheral.writeValue(payload, for: characteristic, type: .withResponse)
        }
    }

    private func writeControlCommand(_ cmd: UInt8) {
        writeControlPayload(Data([cmd]))
    }

    private func writeControlPayload(_ payload: Data) {
        guard let peripheral = activePeripheral, let characteristic = controlCharacteristic else { return }
        if writeContinuation != nil { return }
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
        addLog(.ble, "Đang mở kết nối GATT...", "Target: \(device.name ?? "Honda_AB2025_Dash")")
        centralManager.connect(device, options: nil)

        connectTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.connecting else { return }
            self.connecting = false
            self.connectionState = .error("Connect timeout, dang thu lai...")
            self.addLog(.ble, "Timeout kết nối GATT (10s)", "Đóng phiên và tự kết nối lại...", isError: true)
            self.centralManager.cancelPeripheralConnection(device)
            self.scheduleReconnect()
        }
        connectTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + connectTimeout, execute: work)
    }

    private func scheduleReconnect() {
        guard let device = activePeripheral else {
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

    private func parseTelemetryPacket(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 12 else {
            addLog(.packet, "Gói Telemetry quá ngắn (\(bytes.count)B)", isError: true)
            return
        }
        var crc12: UInt8 = 0
        for i in 0..<11 { crc12 ^= bytes[i] }
        guard crc12 == bytes[11] else {
            addLog(.packet, "Lỗi CRC12 gói Telemetry", String(format: "Expected 0x%02X != 0x%02X", crc12, bytes[11]), isError: true)
            return
        }

        let rpm = (Int(bytes[0]) << 8) | Int(bytes[1])
        let speed = Int(bytes[2])
        let ect = Int(Int8(bitPattern: bytes[3]))
        let tps = Int(bytes[4])
        let voltScaled = (Int(bytes[5]) << 8) | Int(bytes[6])
        let batteryV = Float(voltScaled) / 100.0
        let iat = Int(Int8(bitPattern: bytes[7]))
        let o2Scaled = (Int(bytes[8]) << 8) | Int(bytes[9])
        let o2V = Float(o2Scaled) / 100.0
        let ecuConnected = (bytes[10] & 0x01) != 0

        var ignTiming: Int?
        var injTi: Int?
        var switches = 0
        var runTimeSec: Int?
        var engineLoad: Int?

        if bytes.count >= 20 {
            var crc20: UInt8 = 0
            for i in 0..<19 { crc20 ^= bytes[i] }
            if crc20 == bytes[19] {
                ignTiming = Int(Int8(bitPattern: bytes[12]))
                injTi = (Int(bytes[13]) << 8) | Int(bytes[14])
                switches = Int(bytes[15])
                runTimeSec = (Int(bytes[16]) << 8) | Int(bytes[17])
                engineLoad = Int(bytes[18])
            }
        }

        let now = ProcessInfo.processInfo.systemUptime
        packetCounter += 1
        if lastPacketUptime > 0 {
            let dt = max(0.001, now - lastPacketUptime)
            let instHz = Float(1.0 / dt)
            smoothedHz = smoothedHz == 0 ? instHz : (smoothedHz * 0.8 + instHz * 0.2)
        }
        lastPacketUptime = now

        let hexStr = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")

        if lastLoggedEcuConn != ecuConnected {
            lastLoggedEcuConn = ecuConnected
            if ecuConnected {
                addLog(.kline, "ECU Honda K-Line ĐÃ KẾT NỐI ✓", String(format: "ISO 14230-4 Fast Init (10400 baud) · RPM=%d · Volt=%.2fV", rpm, batteryV))
            } else {
                addLog(.kline, "K-Line chờ phản hồi từ ECU...", "ESP32 đang gửi xung Fast Init (Kiểm tra khóa điện xe ON & dây K-Line chân 16/17)")
            }
        }

        let sideStand = (switches & 0x01) != 0
        if let prevStand = lastLoggedSideStand, prevStand != sideStand {
            if sideStand {
                addLog(.warn, "Phát hiện HẠ CHÂN CHỐNG BÊN", "Bit0 Switch = 1 (Ngắt đề an toàn)", isError: true)
            } else {
                addLog(.kline, "Đã gạt chân chống lên ✓", "Sẵn sàng khởi động")
            }
        }
        lastLoggedSideStand = sideStand

        if logRawPackets || (now - lastSampledPacketLogUptime >= 3.0) {
            lastSampledPacketLogUptime = now
            let extraStr = injTi != nil ? " · Ti=\(injTi ?? 0)us · Ign=\(ignTiming ?? 0)° · Load=\(engineLoad ?? 0)%" : ""
            addLog(
                .packet,
                "RX #\(packetCounter) (\(bytes.count)B) · RPM=\(rpm) · \(speed)km/h · ECT=\(ect)°C",
                String(format: "HEX: %@\nTPS=%d%% · Batt=%.2fV · IAT=%d°C · O2=%.2fV%@", hexStr, tps, batteryV, iat, o2V, extraStr)
            )
        }

        var reading = ecuReading
        reading.rpm = rpm
        reading.speed = speed
        reading.ect = ect
        reading.tps = tps
        reading.battery = batteryV
        reading.iat = iat
        reading.o2Voltage = o2V
        reading.ecuConnected = ecuConnected
        reading.ignitionTiming = ignTiming
        reading.injectorTi = injTi
        reading.switches = switches
        reading.runTimeSec = runTimeSec
        reading.engineLoad = engineLoad
        reading.rawHex = hexStr
        reading.packetCount = packetCounter
        reading.packetHz = smoothedHz
        ecuReading = reading
    }

    private func parseDtcPacket(_ data: Data) {
        let text = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let codes = text.isEmpty ? [] : text.split(separator: ",").map(String.init)
        if !codes.isEmpty {
            addLog(.warn, "Phát hiện \(codes.count) mã lỗi DTC!", "Mã lỗi: \(codes.joined(separator: ", "))", isError: true)
        } else {
            addLog(.kline, "Kiểm tra DTC Mode 03: Không có mã lỗi")
        }
        var reading = ecuReading
        reading.dtcCodes = codes
        ecuReading = reading
    }
}

extension EcuBleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            addLog(.ble, "Bluetooth iOS đã sẵn sàng (PoweredOn)")
            if pendingScanOnPowerOn || (!scanning && !connecting && activePeripheral == nil) {
                startScanAndConnect()
            }
        case .unauthorized:
            connectionState = .error("Chua cap quyen Bluetooth trong Cai dat iOS")
            addLog(.ble, "Chưa cấp quyền Bluetooth cho MotoDash", "Vào Cài đặt iOS -> MotoDash -> Bật Bluetooth", isError: true)
        case .poweredOff:
            connectionState = .error("Bluetooth dang tat")
            addLog(.ble, "Bluetooth trên iPhone đang tắt", "Vui lòng bật Bluetooth để kết nối mạch", isError: true)
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard scanning else { return }
        let advName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? ""
        let advServices = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let overflowServices = (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]) ?? []
        let isMatch = advName.localizedCaseInsensitiveContains("Honda_AB2025")
            || advName.localizedCaseInsensitiveContains("AB2025_Dash")
            || advServices.contains(BleUuids.service)
            || overflowServices.contains(BleUuids.service)
        guard isMatch else { return }

        stopScanQuietly()
        let name = advName.isEmpty ? (peripheral.name ?? "Honda_AB2025_Dash") : advName
        addLog(.ble, "Tìm thấy thiết bị: \(name)", "RSSI: \(RSSI) dBm")
        connectToDevice(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectTimeoutWork?.cancel()
        addLog(.ble, "Đã kết nối vật lý BLE", "Đang dò tìm dịch vụ GATT...")

        discoverTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.connecting else { return }
            self.connecting = false
            self.connectionState = .error("Timeout do tim dich vu, dang thu lai...")
            self.addLog(.ble, "Timeout dò tìm dịch vụ GATT", "Đang thử kết nối lại...", isError: true)
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.scheduleReconnect()
        }
        discoverTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + discoverTimeout, execute: work)

        peripheral.discoverServices([BleUuids.service])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connecting = false
        connectTimeoutWork?.cancel()
        discoverTimeoutWork?.cancel()
        connectionState = .error("Connect that bai, dang thu lai...")
        addLog(.ble, "Kết nối BLE thất bại", error?.localizedDescription ?? "", isError: true)
        scheduleReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connecting = false
        connectTimeoutWork?.cancel()
        discoverTimeoutWork?.cancel()
        controlCharacteristic = nil
        audioDataCharacteristic = nil
        lastLoggedEcuConn = nil
        lastSyncedMask = -1
        lastSyncedVolIdx = -1
        writeTimeoutWork?.cancel()
        if let cont = writeContinuation {
            writeContinuation = nil
            cont.resume(returning: false)
        }
        connectionState = .disconnected
        addLog(.ble, "Đã ngắt kết nối BLE", "Tự động kết nối lại sau 3s...", isError: true)
        scheduleReconnect()
    }
}

extension EcuBleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoverTimeoutWork?.cancel()
        guard let service = peripheral.services?.first(where: { $0.uuid == BleUuids.service }) else {
            connecting = false
            connectionState = .error("Khong tim thay service tren thiet bi, dang thu lai...")
            addLog(.ble, "Không tìm thấy Service Honda_AB2025_Dash", isError: true)
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
        addLog(.ble, "Dò tìm dịch vụ GATT hoàn tất ✓", "Tìm thấy \(characteristics.count) characteristics")

        for uuid in BleUuids.allCharacteristics {
            guard let characteristic = characteristics.first(where: { $0.uuid == uuid }) else { continue }
            peripheral.setNotifyValue(true, for: characteristic)
        }
        controlCharacteristic = characteristics.first(where: { $0.uuid == BleUuids.charControl })
        audioDataCharacteristic = characteristics.first(where: { $0.uuid == BleUuids.charAudioData })
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        handleCharacteristicUpdate(characteristic.uuid, data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        writeTimeoutWork?.cancel()
        if let cont = writeContinuation {
            writeContinuation = nil
            cont.resume(returning: error == nil)
        }
    }
}
