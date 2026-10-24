import Foundation

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
    static let soundBootMusic = "sound_boot_music"
    static let soundConnection = "sound_connection"
    static let soundShiftWarn = "sound_shift_warn"
    static let soundSpeedWarn = "sound_speed_warn"
    static let soundEctWarn = "sound_ect_warn"
    static let soundIgnitionWarn = "sound_ignition_warn"
    static let bootTrackId = "boot_track_id"
    static let warnTrackId = "warn_track_id"
    static let speakerVolIdx = "speaker_vol_idx"
    static let bleDeviceName = "ble_device_name"
}

@MainActor
final class SettingsRepository: ObservableObject {
    private let defaults: UserDefaults

    @Published private(set) var settings: AppSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.load(from: defaults)
    }

    private static func load(from defaults: UserDefaults) -> AppSettings {
        let rawBleName = defaults.string(forKey: Keys.bleDeviceName) ?? "HONDA AB125 Lor"
        let bleName = (rawBleName.isEmpty || rawBleName == "Honda_AB2025_Dash") ? "HONDA AB125 Lor" : rawBleName
        return AppSettings(
            theme: defaults.string(forKey: Keys.theme) ?? "portrait",
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
            brandLogo: defaults.string(forKey: Keys.brandLogo) ?? "honda",
            bleDeviceName: bleName,
            soundBootMusic: defaults.object(forKey: Keys.soundBootMusic) != nil ? defaults.bool(forKey: Keys.soundBootMusic) : true,
            soundConnection: defaults.object(forKey: Keys.soundConnection) != nil ? defaults.bool(forKey: Keys.soundConnection) : true,
            soundShiftWarn: defaults.object(forKey: Keys.soundShiftWarn) != nil ? defaults.bool(forKey: Keys.soundShiftWarn) : true,
            soundSpeedWarn: defaults.object(forKey: Keys.soundSpeedWarn) != nil ? defaults.bool(forKey: Keys.soundSpeedWarn) : true,
            soundEctWarn: defaults.object(forKey: Keys.soundEctWarn) != nil ? defaults.bool(forKey: Keys.soundEctWarn) : true,
            soundIgnitionWarn: defaults.object(forKey: Keys.soundIgnitionWarn) != nil ? defaults.bool(forKey: Keys.soundIgnitionWarn) : true,
            bootTrackId: defaults.object(forKey: Keys.bootTrackId) != nil ? defaults.integer(forKey: Keys.bootTrackId) : 0,
            warnTrackId: defaults.object(forKey: Keys.warnTrackId) != nil ? defaults.integer(forKey: Keys.warnTrackId) : 3,
            speakerVolIdx: defaults.object(forKey: Keys.speakerVolIdx) != nil ? defaults.integer(forKey: Keys.speakerVolIdx) : 0
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
    func setBleDeviceName(_ value: String) { update(Keys.bleDeviceName, value) }
    func setSoundBootMusic(_ value: Bool) { update(Keys.soundBootMusic, value) }
    func setSoundConnection(_ value: Bool) { update(Keys.soundConnection, value) }
    func setSoundShiftWarn(_ value: Bool) { update(Keys.soundShiftWarn, value) }
    func setSoundSpeedWarn(_ value: Bool) { update(Keys.soundSpeedWarn, value) }
    func setSoundEctWarn(_ value: Bool) { update(Keys.soundEctWarn, value) }
    func setSoundIgnitionWarn(_ value: Bool) { update(Keys.soundIgnitionWarn, value) }
    func setBootTrackId(_ value: Int) { update(Keys.bootTrackId, value) }
    func setWarnTrackId(_ value: Int) { update(Keys.warnTrackId, value) }
    func setSpeakerVolIdx(_ value: Int) { update(Keys.speakerVolIdx, value) }

    private func update(_ key: String, _ value: Any) {
        defaults.set(value, forKey: key)
        settings = Self.load(from: defaults)
    }
}
