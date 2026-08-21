import Foundation

/// Mirrors the exact keys/defaults read by the Kotlin source's data/AppSettings.kt
/// (in turn mirroring www/settings.html's localStorage keys).
struct AppSettings: Equatable {
    var theme: String = "sport" // sport|daily|classic|crazy
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
    var brandLogo: String = "bmw"

    var shiftRpmThreshold: Int { shiftWarnEnabled ? rpmWarnVal * 1000 : Int.max }
}
