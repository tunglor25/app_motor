import Foundation

/// Local JSON persistence for drag-run history, mirroring the Kotlin source's
/// data/DragRepository.kt (same pattern as TripRepository). Personal best =
/// the run with the smallest to60Ms among runs that ever reached 60 km/h.
actor DragRepository {
    private let maxRuns = 20
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("drag_runs.json")
    }

    func save(_ run: DragRun) {
        var all = readAll()
        all.append(run)
        if all.count > maxRuns {
            all.sort { $0.timestamp < $1.timestamp }
            all = Array(all.suffix(maxRuns))
        }
        writeAll(all)
    }

    func getBest() -> DragRun? {
        readAll().compactMap { run in run.to60Ms.map { (run, $0) } }.min { $0.1 < $1.1 }?.0
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func readAll() -> [DragRun] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DragRun].self, from: data)) ?? []
    }

    private func writeAll(_ runs: [DragRun]) {
        guard let data = try? JSONEncoder().encode(runs) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
