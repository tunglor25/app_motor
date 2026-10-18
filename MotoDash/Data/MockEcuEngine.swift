import Foundation

@MainActor
final class MockEcuEngine: ObservableObject {
    @Published private(set) var reading = EcuReading()

    private var timer: Timer?
    private var phase: Double = 0
    private var ect = 28
    private var tickCount = 0
    private var launchTick = -1

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
            reading = EcuReading(
                rpm: 1300, speed: 0, ect: ect, tps: 5, battery: 13.4, iat: 24, o2Voltage: 0.2,
                ecuConnected: true, ignitionTiming: 12, injectorTi: 2150, switches: 0,
                runTimeSec: tickCount / 2, engineLoad: 14,
                rawHex: "05 14 00 1C 05 05 3C 18 00 14 01 3B 0C 08 66 00 00 78 0E 4A",
                packetCount: Int64(tickCount), packetHz: 2.5
            )
        } else if (4...23).contains(t) {
            let launchT = Double(t - 4) / 19.0
            let rpm = min(max(Int(1300 + launchT * 9500), 1300), 12800)
            let speed = min(max(Int(launchT * launchT * 92), 0), 95)
            reading = EcuReading(
                rpm: rpm, speed: speed, ect: ect, tps: 96, battery: 14.1, iat: 24, o2Voltage: 0.6,
                ecuConnected: true, ignitionTiming: 28, injectorTi: 6850, switches: 0,
                runTimeSec: tickCount / 2, engineLoad: 94,
                rawHex: "2A 30 58 5A 60 05 82 18 00 3C 01 7E 1C 1A C2 00 00 90 5E 12",
                packetCount: Int64(tickCount), packetHz: 2.5
            )
        } else {
            if t >= 24 { launchTick = -1 }
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
            let ign = 10 + (rpm * 22 / 10000)
            let ti = 1800 + (tps * 45) + (rpm / 5)
            let load = min(max((tps * 65 + (rpm * 100 / 10000) * 35) / 100, 8), 100)
            reading = EcuReading(
                rpm: rpm, speed: speed, ect: ect, tps: tps, battery: battery, iat: iat, o2Voltage: o2,
                ecuConnected: true, ignitionTiming: ign, injectorTi: ti, switches: 0,
                runTimeSec: tickCount / 2, engineLoad: load,
                rawHex: String(format: "%02X %02X %02X %02X %02X 05 64 %02X 00 28 01 AA %02X %02X %02X 00 00 %02X %02X 55",
                               (rpm >> 8) & 0xFF, rpm & 0xFF, speed, ect, tps, iat, ign, (ti >> 8) & 0xFF, ti & 0xFF, (tickCount / 2) & 0xFF, load),
                packetCount: Int64(tickCount), packetHz: 2.5
            )
        }
    }
}
