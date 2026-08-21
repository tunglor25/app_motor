import Foundation

struct RoutePoint: Codable, Equatable {
    var lat: Double
    var lng: Double
    var timestamp: Int64 // epoch ms
    var speedGPS: Double
}

/// Exact field-for-field mirror of the trip object saved by the Kotlin source's
/// data/TripRecord.kt.
struct TripRecord: Codable, Equatable, Identifiable {
    var id: String
    var startTime: Int64 // epoch ms
    var endTime: Int64 // epoch ms
    var duration: Int64 // ms
    var totalDistance: Double
    var maxSpeedECU: Double
    var maxSpeedGPS: Double
    var avgSpeedECU: Double
    var avgSpeedGPS: Double
    var maxRPM: Int
    var avgRPM: Double
    var maxECT: Int
    // Always 0 -- never set natively, matches the web app (dead field, fuel calc
    // is fake there too). Kept for shape-parity but never displayed anywhere.
    var fuelConsumed: Double = 0.0
    var routeCoords: [RoutePoint] = []
    var sampleCountECU: Int
    var sampleCountGPS: Int
}
