import Foundation

enum DragState {
    case idle, staged, running, finished
}

private let armSpeedThresholdKmh = 3   // dung han thay vi doi dung 0 tuyet doi
private let launchTpsThreshold = 80    // vot ga het co
private let maxRunMs: Int64 = 20_000   // ngat an toan neu khong bao gio toi 60km/h
private let abortAfterMs: Int64 = 800  // xe dung lai giua chung (nha ga som)
private let letOffDeltaKmh = 15        // toc do tut bao nhieu duoi dinh la coi nhu da nha ga

/// Bam gio 0-40/0-60/100m tu chinh du lieu Speed/TPS/RPM da co san qua BLE --
/// khong can GPS. Goi onReading() lien tuc tu vong doc ECU (bao gom ca demo
/// mode); tu phat hien luc nao nen bat dau/ket thuc. Mirrors the Kotlin
/// source's data/DragRecorder.kt.
@MainActor
final class DragRecorder: ObservableObject {
    @Published private(set) var state: DragState = .idle
    @Published private(set) var elapsedMs: Int64 = 0
    @Published private(set) var to40Ms: Int64?
    @Published private(set) var to60Ms: Int64?
    @Published private(set) var to100mMs: Int64?
    @Published private(set) var lastRun: DragRun?
    @Published private(set) var bestRun: DragRun?
    @Published private(set) var isNewRecord = false

    private let repository: DragRepository
    private var startTimeMs: Int64 = 0
    private var lastSampleTimeMs: Int64 = 0
    private var distanceM: Double = 0
    private var lastSpeedKmh = 0
    private var peakSpeedKmh = 0
    private var samples: [DragSample] = []
    var onFinished: ((DragRun) -> Void)?

    init(repository: DragRepository) {
        self.repository = repository
    }

    func loadBest() async {
        bestRun = await repository.getBest()
    }

    /// Nguoi dung mo man hinh Drag -- bat dau doi xe dung han de "san sang".
    func arm() {
        if state == .idle || state == .finished {
            reset()
            state = .staged
        }
    }

    func cancel() {
        reset()
        state = .idle
    }

    func onReading(_ reading: EcuReading, nowMs: Int64 = Int64(ProcessInfo.processInfo.systemUptime * 1000)) {
        guard let speed = reading.speed else { return }
        let rpm = reading.rpm ?? 0
        let tps = reading.tps ?? 0

        switch state {
        case .staged:
            if speed <= armSpeedThresholdKmh, tps >= launchTpsThreshold {
                startTimeMs = nowMs
                lastSampleTimeMs = nowMs
                distanceM = 0
                lastSpeedKmh = 0
                peakSpeedKmh = 0
                samples = [DragSample(timeMs: 0, speedKmh: 0, rpm: rpm)]
                to40Ms = nil
                to60Ms = nil
                to100mMs = nil
                elapsedMs = 0
                state = .running
            }

        case .running:
            let dtMs = max(nowMs - lastSampleTimeMs, 0)
            let avgSpeedKmh = Double(lastSpeedKmh + speed) / 2.0
            distanceM += avgSpeedKmh * (Double(dtMs) / 3_600_000.0) * 1000.0
            lastSampleTimeMs = nowMs
            lastSpeedKmh = speed
            if speed > peakSpeedKmh { peakSpeedKmh = speed }

            let elapsed = nowMs - startTimeMs
            elapsedMs = elapsed
            samples.append(DragSample(timeMs: elapsed, speedKmh: speed, rpm: rpm))

            if to40Ms == nil, speed >= 40 { to40Ms = elapsed }
            if to60Ms == nil, speed >= 60 { to60Ms = elapsed }
            if to100mMs == nil, distanceM >= 100.0 { to100mMs = elapsed }

            let gotBothTargets = to60Ms != nil && to100mMs != nil
            let timedOut = elapsed >= maxRunMs
            let aborted = speed == 0 && elapsed >= abortAfterMs
            // Nguoi lai da nha ga ro ret (toc do tut xa duoi dinh) sau khi da dat
            // toc do 60 -- ket thuc luon thay vi cho mai toi khi du 100m.
            let throttleLetOff = to60Ms != nil && peakSpeedKmh > 0 && speed <= peakSpeedKmh - letOffDeltaKmh
            if gotBothTargets || timedOut || aborted || throttleLetOff {
                finish()
            }

        default:
            break
        }
    }

    private func finish() {
        let run = DragRun(
            id: UUID().uuidString,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            to40Ms: to40Ms,
            to60Ms: to60Ms,
            to100mMs: to100mMs,
            samples: samples
        )
        lastRun = run
        state = .finished

        let beatsRecord = run.to60Ms != nil && (bestRun?.to60Ms == nil || run.to60Ms! < bestRun!.to60Ms!)
        isNewRecord = beatsRecord
        if beatsRecord { bestRun = run }

        onFinished?(run)
    }

    private func reset() {
        startTimeMs = 0
        lastSampleTimeMs = 0
        distanceM = 0
        lastSpeedKmh = 0
        peakSpeedKmh = 0
        samples = []
        elapsedMs = 0
        to40Ms = nil
        to60Ms = nil
        to100mMs = nil
        isNewRecord = false
    }
}
