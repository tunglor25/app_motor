import Foundation

private let accuracyFilterM: Double = 30
private let earthRadiusKm: Double = 6371.0

/// Same formula/constants as the Kotlin source's haversineKm().
func haversineKm(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadiusKm * c
}

/// In-memory accumulator for a single active recording, mirrors the Kotlin
/// source's data/TripRecorderSession.kt live state.
final class TripRecorderSession {
    private(set) var startedAt: Int64 = 0 // epoch ms
    private(set) var totalDistanceKm: Double = 0
    private(set) var maxSpeedGpsKmh: Double = 0

    private var lastCoord: RoutePoint?
    private var routeCoords: [RoutePoint] = []
    private var sumSpeedGps: Double = 0
    private var sampleCountGps = 0

    private var maxSpeedEcu: Double = 0
    private var sumSpeedEcu: Double = 0
    private var sampleCountEcu = 0
    private var maxRpm = 0
    private var sumRpm: Double = 0
    private var maxEct = 0

    func start() {
        startedAt = Int64(Date().timeIntervalSince1970 * 1000)
        totalDistanceKm = 0
        maxSpeedGpsKmh = 0
        lastCoord = nil
        routeCoords.removeAll()
        sumSpeedGps = 0
        sampleCountGps = 0
        maxSpeedEcu = 0
        sumSpeedEcu = 0
        sampleCountEcu = 0
        maxRpm = 0
        sumRpm = 0
        maxEct = 0
    }

    // Points with accuracy worse than 30m are dropped entirely, matching the source.
    func addGpsPoint(lat: Double, lng: Double, speedKmh: Double, timestamp: Int64, accuracyM: Double) {
        guard accuracyM <= accuracyFilterM else { return }
        let point = RoutePoint(lat: lat, lng: lng, timestamp: timestamp, speedGPS: speedKmh)
        if let previous = lastCoord {
            totalDistanceKm += haversineKm(previous.lat, previous.lng, lat, lng)
        }
        lastCoord = point
        routeCoords.append(point)
        if speedKmh > maxSpeedGpsKmh { maxSpeedGpsKmh = speedKmh }
        sumSpeedGps += speedKmh
        sampleCountGps += 1
    }

    func addEcuSample(speed: Int?, rpm: Int?, ect: Int?) {
        if let speed {
            if Double(speed) > maxSpeedEcu { maxSpeedEcu = Double(speed) }
            sumSpeedEcu += Double(speed)
        }
        if let rpm {
            if rpm > maxRpm { maxRpm = rpm }
            sumRpm += Double(rpm)
        }
        if let ect, ect > maxEct { maxEct = ect }
        if speed != nil || rpm != nil { sampleCountEcu += 1 }
    }

    func stop() -> TripRecord {
        let endTime = Int64(Date().timeIntervalSince1970 * 1000)
        return TripRecord(
            id: "trip_\(startedAt)",
            startTime: startedAt,
            endTime: endTime,
            duration: endTime - startedAt,
            totalDistance: totalDistanceKm,
            maxSpeedECU: maxSpeedEcu,
            maxSpeedGPS: maxSpeedGpsKmh,
            avgSpeedECU: sampleCountEcu > 0 ? sumSpeedEcu / Double(sampleCountEcu) : 0,
            avgSpeedGPS: sampleCountGps > 0 ? sumSpeedGps / Double(sampleCountGps) : 0,
            maxRPM: maxRpm,
            avgRPM: sampleCountEcu > 0 ? sumRpm / Double(sampleCountEcu) : 0,
            maxECT: maxEct,
            fuelConsumed: 0,
            routeCoords: routeCoords,
            sampleCountECU: sampleCountEcu,
            sampleCountGPS: sampleCountGps
        )
    }
}
