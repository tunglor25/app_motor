import Foundation

/// Local JSON persistence mirroring the Kotlin source's data/TripRepository.kt
/// (localStorage['trip_history'] equivalent, capped at 50 trips). Deliberately a
/// plain JSON file via FileManager rather than CoreData/SwiftData, to minimize
/// what could go wrong compiling blind.
actor TripRepository {
    private let maxTrips = 50
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("trip_history.json")
    }

    func getAllTrips() -> [TripRecord] {
        readAll().sorted { $0.startTime > $1.startTime }
    }

    func getTripById(_ id: String) -> TripRecord? {
        readAll().first { $0.id == id }
    }

    func save(_ trip: TripRecord) {
        var all = readAll()
        all.append(trip)
        if all.count > maxTrips {
            all.sort { $0.startTime < $1.startTime }
            all = Array(all.suffix(maxTrips))
        }
        writeAll(all)
    }

    func deleteTrip(_ id: String) {
        writeAll(readAll().filter { $0.id != id })
    }

    func clearAllTrips() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func readAll() -> [TripRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([TripRecord].self, from: data)) ?? []
    }

    private func writeAll(_ trips: [TripRecord]) {
        guard let data = try? JSONEncoder().encode(trips) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
