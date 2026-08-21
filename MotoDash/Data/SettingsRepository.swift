import Foundation

// Key names match the Kotlin source's data/SettingsRepository.kt (in turn
// www/settings.html's localStorage keys) 1:1 for easy cross-reference.
private enum Keys {
    static let theme = "theme"
    static let unitSpeed = "unit_speed"
    static let unitTemp = "unit_temp"
    static let speedWarnEnabled = "speed_warn_enabled"
    static let shiftWarnEnabled = "shift_warn_enabled"
    static let rpmWarnVal = "rpm_warn_val"
    static let autoConnect = "auto_connect"
    static let wakeLock = "wake_lock"
    static let fullscreen = "fullscreen"
    static let lightMode = "light_mode"
    static let autoHideMusic = "auto_hide_music"
    static let demoMode = "demo_mode"
    static let brandLogo = "brand_logo"
}

/// UserDefaults-backed settings store -- the iOS equivalent of the Kotlin
/// source's DataStore-backed SettingsRepository.kt. UserDefaults writes are
/// synchronous, so unlike the Kotlin suspend functions, these setters are plain.
@MainActor
final class SettingsRepository: ObservableObject {
    private let defaults: UserDefaults

    @Published private(set) var settings: AppSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.load(from: defaults)
    }

    private static func load(from defaults: UserDefaults) -> AppSettings {
        AppSettings(
            theme: defaults.string(forKey: Keys.theme) ?? "sport",
            unitSpeed: defaults.string(forKey: Keys.unitSpeed) ?? "kmh",
            unitTemp: defaults.string(forKey: Keys.unitTemp) ?? "c",
            speedWarnEnabled: defaults.bool(forKey: Keys.speedWarnEnabled),
            shiftWarnEnabled: defaults.object(forKey: Keys.shiftWarnEnabled) != nil ? defaults.bool(forKey: Keys.shiftWarnEnabled) : true,
            rpmWarnVal: defaults.object(forKey: Keys.rpmWarnVal) != nil ? defaults.integer(forKey: Keys.rpmWarnVal) : 11,
            autoConnect: defaults.object(forKey: Keys.autoConnect) != nil ? defaults.bool(forKey: Keys.autoConnect) : true,
            wakeLock: defaults.object(forKey: Keys.wakeLock) != nil ? defaults.bool(forKey: Keys.wakeLock) : true,
            fullscreen: defaults.object(forKey: Keys.fullscreen) != nil ? defaults.bool(forKey: Keys.fullscreen) : true,
            lightMode: defaults.bool(forKey: Keys.lightMode),
            autoHideMusic: defaults.object(forKey: Keys.autoHideMusic) != nil ? defaults.bool(forKey: Keys.autoHideMusic) : true,
            demoMode: defaults.bool(forKey: Keys.demoMode),
            brandLogo: defaults.string(forKey: Keys.brandLogo) ?? "bmw"
        )
    }

    func setTheme(_ value: String) { update(Keys.theme, value) }
    func setUnitSpeed(_ value: String) { update(Keys.unitSpeed, value) }
    func setUnitTemp(_ value: String) { update(Keys.unitTemp, value) }
    func setSpeedWarnEnabled(_ value: Bool) { update(Keys.speedWarnEnabled, value) }
    func setShiftWarnEnabled(_ value: Bool) { update(Keys.shiftWarnEnabled, value) }
    func setRpmWarnVal(_ value: Int) { update(Keys.rpmWarnVal, value) }
    func setAutoConnect(_ value: Bool) { update(Keys.autoConnect, value) }
    func setWakeLock(_ value: Bool) { update(Keys.wakeLock, value) }
    func setFullscreen(_ value: Bool) { update(Keys.fullscreen, value) }
    func setLightMode(_ value: Bool) { update(Keys.lightMode, value) }
    func setAutoHideMusic(_ value: Bool) { update(Keys.autoHideMusic, value) }
    func setDemoMode(_ value: Bool) { update(Keys.demoMode, value) }
    func setBrandLogo(_ value: String) { update(Keys.brandLogo, value) }

    private func update(_ key: String, _ value: Any) {
        defaults.set(value, forKey: key)
        settings = Self.load(from: defaults)
    }
}
