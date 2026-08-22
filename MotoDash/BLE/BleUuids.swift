import CoreBluetooth

/// Ground truth mirrored from the ESP32-S3 firmware and the Kotlin source's
/// ble/BleUuids.kt. Do not change without updating the firmware.
enum BleUuids {
    static let deviceName = "Honda_AB2025_Dash"

    static let service = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")

    // Gop 7 characteristic rieng le cu thanh 1 goi telemetry 12-byte duy nhat --
    // xem parseTelemetryPacket() trong EcuBleManager.swift de biet cau truc
    // byte chinh xac. Thay doi giao thuc, khong con tuong thich nguoc.
    static let charTelemetry = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let charDTC = CBUUID(string: "d7e8f9a0-1b2c-4d3e-8f4a-5b6c7d8e9f0a")
    static let charControl = CBUUID(string: "aab1c2d3-e4f5-4a6b-8c7d-1e2f3a4b5c6d")

    static let allCharacteristics: [CBUUID] = [charTelemetry, charDTC]

    /// 'C' -- troll command sent from the app, unrelated to any real ECU data.
    static let cmdC4: UInt8 = 0x43
    /// 'D' -- clears real ECU trouble codes via Mode 04.
    static let cmdClearDtc: UInt8 = 0x44
    /// 'S' -- cai dat bat/tat am thanh coi & loa ESP32.
    static let cmdSetSound: UInt8 = 0x53
}
