import Foundation

struct DashboardUiState {
    var connectionState: BleConnectionState = .idle
    var reading = EcuReading()
    var tripKm: Double = 0.0
    var lapText: String = "00:00.0"
    var lapRunning: Bool = false
    var isTripRecording: Bool = false
    var liveTripStats = LiveTripStats()
    var speedLimitKmh: Int = 0
    var settings = AppSettings()
    var resetFlash: Bool = false
    var savedTripId: String?
}
