import Foundation

/// One data point along the acceleration curve, recorded throughout a run.
struct DragSample: Codable, Equatable {
    let timeMs: Int64
    let speedKmh: Int
    let rpm: Int
}

/// Result of one drag/acceleration measurement. to40Ms/to60Ms/to100mMs are nil
/// if that milestone was never reached (e.g. throttle let off before 60 km/h).
struct DragRun: Codable, Equatable, Identifiable {
    let id: String
    let timestamp: Int64
    let to40Ms: Int64?
    let to60Ms: Int64?
    let to100mMs: Int64?
    let samples: [DragSample]
}
