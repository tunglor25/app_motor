import Foundation

/// In-memory-only distance accumulation from speed deltas, mirroring the Kotlin
/// source's data/TripOdometer.kt (dist = speed * deltaSeconds/3600).
final class TripOdometer {
    private var distanceKm: Double = 0
    private var lastUpdate: TimeInterval?

    func onSpeedSample(_ speedKmh: Int) -> Double {
        let now = ProcessInfo.processInfo.systemUptime
        if let previous = lastUpdate {
            let deltaSeconds = now - previous
            distanceKm += Double(speedKmh) * deltaSeconds / 3600.0
        }
        lastUpdate = now
        return distanceKm
    }

    func reset() {
        distanceKm = 0
        lastUpdate = nil
    }
}
