import Foundation

/// Mirrors the exact keys/defaults read by the Kotlin source's data/AppSettings.kt
struct AppSettings: Equatable {
    var theme: String = "sport" // sport|cyber|airblade|superbike|daily|classic|crazy
    var unitSpeed: String = "kmh" // kmh|mph
    var unitTemp: String = "c" // c|f
    var speedWarnEnabled: Bool = false
    var shiftWarnEnabled: Bool = true
    var rpmWarnVal: Int = 11 // x1000, range 4..16
    var autoConnect: Bool = true
    var wakeLock: Bool = true
    var fullscreen: Bool = true
    var lightMode: Bool = false
    var autoHideMusic: Bool = true
    var demoMode: Bool = false
    var brandLogo: String = "honda"

    // Cai dat am thanh coi & loa ESP32 (dong bo qua BLE)
    var soundBootMusic: Bool = true
    var soundConnection: Bool = true
    var soundShiftWarn: Bool = true
    var soundSpeedWarn: Bool = true
    var soundEctWarn: Bool = true
    var soundIgnitionWarn: Bool = true

    // Luu bo nho bai nhac & am luong loa MAX98357A
    var bootTrackId: Int = 0 // 0=#6 Okaerinasai, 1=#7 Gundam, 2=#12 Do Mixi
    var warnTrackId: Int = 3 // 3=#9 Tieng Viet, 4=#11 Tieng Nhat
    var speakerVolIdx: Int = 0 // 0=135% RO, 1=200% XUYEN COP, 2=100% VUA, 3=50% NHO

    var shiftRpmThreshold: Int { shiftWarnEnabled ? rpmWarnVal * 1000 : Int.max }

    var soundBitmask: UInt8 {
        var mask: UInt8 = 0
        if soundBootMusic { mask |= 0x01 }
        if soundConnection { mask |= 0x02 }
        if soundShiftWarn { mask |= 0x04 }
        if soundSpeedWarn { mask |= 0x08 }
        if soundEctWarn { mask |= 0x10 }
        if soundIgnitionWarn { mask |= 0x20 }
        return mask
    }
}
