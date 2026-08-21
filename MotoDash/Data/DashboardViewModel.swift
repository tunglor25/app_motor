import Combine
import Foundation

/// Ties together BLE, settings, mock/demo data, GPS trip recording, and speed
/// limit tracking into a single published DashboardUiState. Functionally mirrors
/// the Kotlin source's data/DashboardViewModel.kt, but instead of chaining
/// several StateFlow combine() operators, each source is subscribed individually
/// and folds its update into `state` directly -- simpler in Swift/Combine and
/// avoids deeply nested CombineLatest generic chains.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state = DashboardUiState()

    let bleManager = EcuBleManager()
    let tripRepository = TripRepository()
    let settingsRepository = SettingsRepository()

    private let tripOdometer = TripOdometer()
    private let gpsTripRecorder: GpsTripRecorder
    private let mockEcuEngine = MockEcuEngine()
    private let speedLimitTracker = SpeedLimitTracker()

    private var lapStartUptime: TimeInterval?
    private var lapTimer: Timer?

    private var cancellables = Set<AnyCancellable>()

    init() {
        gpsTripRecorder = GpsTripRecorder(tripRepository: tripRepository)

        bleManager.$connectionState
            .sink { [weak self] _ in self?.refreshConnectionAndReading() }
            .store(in: &cancellables)
        bleManager.$ecuReading
            .sink { [weak self] _ in self?.refreshConnectionAndReading() }
            .store(in: &cancellables)
        mockEcuEngine.$reading
            .sink { [weak self] _ in self?.refreshConnectionAndReading() }
            .store(in: &cancellables)

        settingsRepository.$settings
            .sink { [weak self] settings in
                guard let self else { return }
                self.state.settings = settings
                self.refreshConnectionAndReading()
                // Only track real GPS speed-limit lookups when the user has opted in
                // and we're not in demo mode, matching the Kotlin source's gate.
                if settings.speedWarnEnabled, !settings.demoMode {
                    self.speedLimitTracker.start()
                } else {
                    self.speedLimitTracker.stop()
                }
            }
            .store(in: &cancellables)

        gpsTripRecorder.$isRecording
            .sink { [weak self] value in self?.state.isTripRecording = value }
            .store(in: &cancellables)
        gpsTripRecorder.$liveStats
            .sink { [weak self] value in self?.state.liveTripStats = value }
            .store(in: &cancellables)

        speedLimitTracker.$speedLimitKmh
            .sink { [weak self] value in self?.state.speedLimitKmh = value }
            .store(in: &cancellables)
    }

    private func refreshConnectionAndReading() {
        let effectiveReading: EcuReading
        if state.settings.demoMode {
            state.connectionState = .connected
            effectiveReading = mockEcuEngine.reading
        } else {
            state.connectionState = bleManager.connectionState
            effectiveReading = bleManager.ecuReading
        }
        state.reading = effectiveReading
        if let speed = effectiveReading.speed {
            state.tripKm = tripOdometer.onSpeedSample(speed)
        }
        gpsTripRecorder.addEcuSample(speed: effectiveReading.speed, rpm: effectiveReading.rpm, ect: effectiveReading.ect)
    }

    func connect() {
        if bleManager.isBluetoothEnabled() {
            bleManager.startScanAndConnect()
        }
    }

    func toggleLapTimer() {
        let runningNow = lapStartUptime != nil
        if !runningNow {
            lapStartUptime = ProcessInfo.processInfo.systemUptime
            state.lapRunning = true
            lapTimer?.invalidate()
            lapTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tickLap() }
            }
        } else {
            lapTimer?.invalidate()
            lapTimer = nil
            lapStartUptime = nil
            state.lapRunning = false
        }
    }

    private func tickLap() {
        guard let start = lapStartUptime else { return }
        let elapsedMs = Int64((ProcessInfo.processInfo.systemUptime - start) * 1000)
        state.lapText = Self.formatLap(elapsedMs)
    }

    /// SET long-press: clears lap timer + ECU-speed trip odometer, with a brief flash.
    func resetAll() {
        lapTimer?.invalidate()
        lapTimer = nil
        lapStartUptime = nil
        state.lapRunning = false
        state.lapText = "00:00.0"
        tripOdometer.reset()
        state.tripKm = 0.0
        state.resetFlash = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            state.resetFlash = false
        }
    }

    func startTripRecording() {
        gpsTripRecorder.start()
    }

    func stopTripRecordingAndSave() {
        Task { @MainActor in
            state.savedTripId = await gpsTripRecorder.stopAndSave()
        }
    }

    func consumeSavedTripId() {
        state.savedTripId = nil
    }

    func disconnectBle() { bleManager.disconnect() }

    func triggerC4Mode() { bleManager.triggerC4Mode() }
    func reconnectBle() { connect() }

    func setTheme(_ theme: String) { settingsRepository.setTheme(theme) }
    func setUnitSpeed(_ value: String) { settingsRepository.setUnitSpeed(value) }
    func setUnitTemp(_ value: String) { settingsRepository.setUnitTemp(value) }
    func setSpeedWarnEnabled(_ enabled: Bool) { settingsRepository.setSpeedWarnEnabled(enabled) }
    func setShiftWarnEnabled(_ enabled: Bool) { settingsRepository.setShiftWarnEnabled(enabled) }
    func setRpmWarnVal(_ value: Int) { settingsRepository.setRpmWarnVal(value) }
    func setAutoConnect(_ enabled: Bool) { settingsRepository.setAutoConnect(enabled) }
    func setWakeLock(_ enabled: Bool) { settingsRepository.setWakeLock(enabled) }
    func setFullscreen(_ enabled: Bool) { settingsRepository.setFullscreen(enabled) }
    func setDemoMode(_ enabled: Bool) { settingsRepository.setDemoMode(enabled) }
    func setAutoHideMusic(_ enabled: Bool) { settingsRepository.setAutoHideMusic(enabled) }

    func clearAllTrips() {
        Task { @MainActor in await tripRepository.clearAllTrips() }
    }

    private static func formatLap(_ elapsedMs: Int64) -> String {
        let totalTenths = elapsedMs / 100
        let minutes = totalTenths / 600
        let seconds = (totalTenths / 10) % 60
        let tenths = totalTenths % 10
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    func onDisappearCleanup() {
        bleManager.disconnect()
        lapTimer?.invalidate()
        gpsTripRecorder.cancel()
        speedLimitTracker.stop()
    }
}
