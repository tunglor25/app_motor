import CoreBluetooth

/// Ground truth mirrored from the ESP32-S3 firmware and the Kotlin source's
/// ble/BleUuids.kt. Do not change without updating the firmware.
enum BleUuids {
    static let deviceName = "Honda_AB2025_Dash"

    static let service = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")

    static let charTelemetry = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let charDTC = CBUUID(string: "d7e8f9a0-1b2c-4d3e-8f4a-5b6c7d8e9f0a")
    static let charControl = CBUUID(string: "aab1c2d3-e4f5-4a6b-8c7d-1e2f3a4b5c6d")
    static let charAudioData = CBUUID(string: "b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e")

    static let allCharacteristics: [CBUUID] = [charTelemetry, charDTC]

    /// 'C' -- troll command sent from the app, unrelated to any real ECU data.
    static let cmdC4: UInt8 = 0x43
    /// 'D' -- clears real ECU trouble codes via Mode 04.
    static let cmdClearDtc: UInt8 = 0x44
    /// 'S' -- cai dat bat/tat am thanh coi & loa ESP32.
    static let cmdSetSound: UInt8 = 0x53
    /// 'U' -- bat dau Upload nhac chao tuy chinh, payload [cmd,size0..size3] uint32 LE.
    static let cmdAudioStart: UInt8 = 0x55
    /// 'E' -- End upload, xac nhan tong so byte da nhan khop khai bao.
    static let cmdAudioEnd: UInt8 = 0x45
    /// 'X' -- quay ve nhac chao mac dinh (PROGMEM), khong xoa file da upload.
    static let cmdAudioUseDefault: UInt8 = 0x58
    /// 'B' -- chon va phat thu nhac khoi dong (Track ID 0..2).
    static let cmdSelectBootTrack: UInt8 = 0x42
    /// 'W' -- chon va phat thu canh bao quen tat khoa (Track ID 3..4 + coi HXD).
    static let cmdSelectWarnTrack: UInt8 = 0x57
    /// 'P' -- phat thu bat ky Track ID 0..4.
    static let cmdPlayTrack: UInt8 = 0x50
    /// 'V' -- doi am luong loa MAX98357A (VolIdx 0..3).
    static let cmdSetVolume: UInt8 = 0x56
}
