import Foundation

/// Synthetic ECU data for demo mode so the whole UI can be previewed with no
/// ESP32 nearby. Exact port of the Kotlin source's data/MockEcuEngine.kt: RPM
/// oscillates around a slowly drifting baseline with the occasional rev, speed
/// follows RPM, ECT climbs toward ~90 and holds, TPS tracks RPM changes,
/// battery/O2 jitter within realistic ranges. Every ~112 ticks (~45s at
/// TICK_MS=400ms) it also simulates a full stop followed by a hard launch
/// (0 -> ~90km/h over ~8s) so the Drag Timer feature can be exercised in demo
/// mode with no real bike.
@MainActor
final class MockEcuEngine: ObservableObject {
    @Published private(set) var reading = EcuReading()

    private var timer: Timer?
    private var phase: Double = 0
    private var ect = 28
    private var tickCount = 0
    private var launchTick = -1 // -1 = not currently in a launch cycle

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func tick() {
        tickCount += 1
        if launchTick < 0, tickCount % 112 == 0 { launchTick = tickCount }
        let t = launchTick >= 0 ? tickCount - launchTick : -1

        if (0...3).contains(t) {
            // Stopped (~1.6s) -- long enough for the Drag screen to arm to "staged".
            reading = EcuReading(rpm: 1300, speed: 0, ect: ect, tps: 5, battery: 13.4, iat: 24, o2Voltage: 0.2)
        } else if (4...23).contains(t) {
            // Wide-open throttle: quadratic acceleration (slow start, ramps up like a real bike).
            let launchT = Double(t - 4) / 19.0
            let rpm = min(max(Int(1300 + launchT * 9500), 1300), 12800)
            let speed = min(max(Int(launchT * launchT * 92), 0), 95)
            reading = EcuReading(rpm: rpm, speed: speed, ect: ect, tps: 96, battery: 14.1, iat: 24, o2Voltage: 0.6)
        } else {
            if t >= 24 { launchTick = -1 } // launch cycle done, back to normal cruising
            phase += 0.15
            let rpmBase = 2500 + Int(sin(phase * 0.3) * 2000)
            let rev = Double.random(in: 0..<1) < 0.05 ? Int.random(in: 1500...4000) : 0
            let rpm = min(max(rpmBase + rev, 900), 12500)
            let speed = min(max(rpm / 130, 0), 95)
            let tps = min(max((rpm - 900) * 100 / 11600, 0), 100)
            if ect < 90, Double.random(in: 0..<1) < 0.3 { ect += 1 }
            let battery: Float = 13.4 + (rpm > 2000 ? 0.4 : 0) + Float.random(in: 0..<1) * 0.2
            let o2 = Float(0.1 + (sin(phase * 1.7) * 0.35 + 0.35))
            let iat = 24 + Int(sin(phase * 0.05) * 4)
            reading = EcuReading(rpm: rpm, speed: speed, ect: ect, tps: tps, battery: battery, iat: iat, o2Voltage: o2)
        }
    }
}
