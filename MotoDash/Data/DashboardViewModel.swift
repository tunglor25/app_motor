import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state = DashboardUiState()
    @Published private(set) var uploadState: AudioUploadState = .idle
    @Published private(set) var logs: [AppLogEntry] = []
    @Published private(set) var logRawPackets: Bool = false

    let bleManager = EcuBleManager()
    let tripRepository = TripRepository()
    let settingsRepository = SettingsRepository()
    let dragRepository = DragRepository()
    let dragRecorder: DragRecorder

    private let tripOdometer = TripOdometer()
    private let gpsTripRecorder: GpsTripRecorder
    private let mockEcuEngine = MockEcuEngine()
    private let speedLimitTracker = SpeedLimitTracker()

    private var lapStartUptime: TimeInterval?
    private var lapTimer: Timer?

    private var cancellables = Set<AnyCancellable>()

    init() {
        gpsTripRecorder = GpsTripRecorder(tripRepository: tripRepository)
        dragRecorder = DragRecorder(repository: dragRepository)
        dragRecorder.onFinished = { [dragRepository] run in
            Task { await dragRepository.save(run) }
        }
        Task { [dragRecorder] in await dragRecorder.loadBest() }

        bleManager.$connectionState
            .sink { [weak self] connState in
                guard let self else { return }
                self.refreshConnectionAndReading()
                if case .connected = connState, !self.state.settings.demoMode {
                    self.bleManager.syncSoundSettings(settings: self.state.settings)
                }
            }
            .store(in: &cancellables)
        bleManager.$ecuReading
            .sink { [weak self] _ in self?.refreshConnectionAndReading() }
            .store(in: &cancellables)
        bleManager.$logs
            .sink { [weak self] value in self?.logs = value }
            .store(in: &cancellables)
        bleManager.$logRawPackets
            .sink { [weak self] value in self?.logRawPackets = value }
            .store(in: &cancellables)
        mockEcuEngine.$reading
            .sink { [weak self] _ in self?.refreshConnectionAndReading() }
            .store(in: &cancellables)

        settingsRepository.$settings
            .sink { [weak self] settings in
                guard let self else { return }
                self.state.settings = settings
                self.refreshConnectionAndReading()
                if case .connected = self.bleManager.connectionState, !settings.demoMode {
                    self.bleManager.syncSoundSettings(settings: settings)
                }
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
        dragRecorder.onReading(effectiveReading)
    }

    func connect() {
        bleManager.startScanAndConnect()
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
    func clearDtc() { bleManager.clearDtc() }
    func reconnectBle() { connect() }

    func clearLogs() { bleManager.clearLogs() }
    func setLogRawPackets(_ enabled: Bool) { bleManager.setLogRawPackets(enabled) }

    func selectBootTrack(trackId: Int, label: String) {
        settingsRepository.setBootTrackId(trackId)
        settingsRepository.setSoundBootMusic(trackId != 255)
        bleManager.selectBootTrack(trackId: trackId, label: label)
    }

    func selectWarnTrack(trackId: Int, label: String) {
        settingsRepository.setWarnTrackId(trackId)
        settingsRepository.setSoundIgnitionWarn(trackId != 255)
        bleManager.selectWarnTrack(trackId: trackId, label: label)
    }

    func setSpeakerVolume(volIdx: Int, label: String) {
        settingsRepository.setSpeakerVolIdx(volIdx)
        bleManager.setSpeakerVolume(volIdx: volIdx, label: label)
    }

    func useDefaultBootMusic() {
        bleManager.useDefaultBootMusic()
        uploadState = .idle
    }

    func uploadBootMusicFromUrl(_ url: URL) {
        Task { @MainActor in
            uploadState = .uploading(0)
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            guard let rawBytes = try? Data(contentsOf: url) else {
                uploadState = .error("Không đọc được file")
                return
            }
            if rawBytes.count > 400_000 {
                uploadState = .error("File quá lớn (tối đa ~12 giây)")
                return
            }
            let result = await bleManager.uploadBootMusic(data: rawBytes) { [weak self] pct in
                Task { @MainActor in self?.uploadState = .uploading(pct) }
            }
            switch result {
            case .success:
                uploadState = .done
            case .failure(let err):
                uploadState = .error(err.localizedDescription)
            }
        }
    }

    func setTheme(_ theme: String) { settingsRepository.setTheme(theme) }
    func setBrandLogo(_ value: String) { settingsRepository.setBrandLogo(value) }
    func setBleDeviceName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        settingsRepository.setBleDeviceName(trimmed)
        bleManager.setBleDeviceName(trimmed)
    }
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
    func setSoundBootMusic(_ enabled: Bool) { settingsRepository.setSoundBootMusic(enabled) }
    func setSoundConnection(_ enabled: Bool) { settingsRepository.setSoundConnection(enabled) }
    func setSoundShiftWarn(_ enabled: Bool) { settingsRepository.setSoundShiftWarn(enabled) }
    func setSoundSpeedWarn(_ enabled: Bool) { settingsRepository.setSoundSpeedWarn(enabled) }
    func setSoundEctWarn(_ enabled: Bool) { settingsRepository.setSoundEctWarn(enabled) }
    func setSoundIgnitionWarn(_ enabled: Bool) { settingsRepository.setSoundIgnitionWarn(enabled) }

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

enum AudioUploadState: Equatable {
    case idle
    case uploading(Float)
    case done
    case error(String)
}
