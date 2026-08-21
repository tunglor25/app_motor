import CoreBluetooth

/// Ground truth mirrored from the ESP32-S3 firmware and the Kotlin source's
/// ble/BleUuids.kt. Do not change without updating the firmware.
enum BleUuids {
    static let deviceName = "Honda_AB2025_Dash"

    static let service = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")

    static let charRPM = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let charSpeed = CBUUID(string: "8b423985-7977-4b72-b2d6-4e5088277be9")
    static let charECT = CBUUID(string: "e3b1c67d-94bb-4286-904b-3cc34a4c6a99")
    static let charTPS = CBUUID(string: "19a28e8d-71b5-4148-84be-97b7cbce39fa")
    static let charBattery = CBUUID(string: "c19f5615-585a-4712-b062-1bd074a1a5b8")
    static let charIAT = CBUUID(string: "d4e8f1a2-3b5c-4d6e-8f9a-0b1c2d3e4f5a")
    static let charO2 = CBUUID(string: "f6a8b1c2-4d5e-4f6a-8b9c-1d2e3f4a5b6c")
    static let charControl = CBUUID(string: "aab1c2d3-e4f5-4a6b-8c7d-1e2f3a4b5c6d")

    static let allCharacteristics: [CBUUID] = [
        charRPM, charSpeed, charECT, charTPS, charBattery, charIAT, charO2,
    ]

    /// 'C' -- troll command sent from the app, unrelated to any real ECU data.
    static let cmdC4: UInt8 = 0x43
}
