import CoreLocation
import Foundation

// Same TomTom endpoint/key and >300m requery threshold as the Kotlin source's
// data/SpeedLimitTracker.kt.
private let tomTomKey = "TNsjEBPR6I6MSu4Lwq1O3YO8udmg5aU3"
private let requeryMeters: Double = 300
private let overpassRadiusM = 200

/// Reverse-geocodes the current GPS position to a posted speed limit. Tries
/// TomTom first, then falls back to OSM Overpass' community-mapped maxspeed
/// tags -- TomTom's response is often valid but missing a speedLimit field for
/// many roads; Overpass has better odds for secondary roads since it's
/// crowd-sourced rather than commercial-survey data. Exact port of the Kotlin
/// source's dual-source logic.
@MainActor
final class SpeedLimitTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var active = false
    private var lastQueryLat: Double?
    private var lastQueryLng: Double?
    private var inFlightTask: Task<Void, Never>?

    @Published private(set) var speedLimitKmh: Int = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50
    }

    func start() {
        guard !active else { return }
        active = true
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
    }

    func stop() {
        active = false
        inFlightTask?.cancel()
        locationManager.stopUpdatingLocation()
        lastQueryLat = nil
        lastQueryLng = nil
        speedLimitKmh = 0
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            maybeQuery(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        }
    }

    private func maybeQuery(lat: Double, lng: Double) {
        let shouldQuery: Bool
        if let lastLat = lastQueryLat, let lastLng = lastQueryLng {
            shouldQuery = haversineMeters(lastLat, lastLng, lat, lng) > requeryMeters
        } else {
            shouldQuery = true
        }
        guard shouldQuery else { return }
        lastQueryLat = lat
        lastQueryLng = lng

        inFlightTask?.cancel()
        inFlightTask = Task { [weak self] in
            guard let self else { return }
            let fromTomTom = await self.fetchFromTomTom(lat: lat, lng: lng)
            let result = fromTomTom ?? (await self.fetchFromOverpass(lat: lat, lng: lng))
            if !Task.isCancelled {
                self.speedLimitKmh = result ?? 0
            }
        }
    }

    private func fetchFromTomTom(lat: Double, lng: Double) async -> Int? {
        guard let url = URL(string: "https://api.tomtom.com/search/2/reverseGeocode/\(lat),\(lng).json?key=\(tomTomKey)&returnSpeedLimit=true") else { return nil }
        guard let body = await httpGet(url) else { return nil }
        guard
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
            let addresses = json["addresses"] as? [[String: Any]],
            let first = addresses.first,
            let address = first["address"] as? [String: Any],
            let speedLimitStr = address["speedLimit"] as? String
        else { return nil }
        return firstIntMatch(in: speedLimitStr)
    }

    private func fetchFromOverpass(lat: Double, lng: Double) async -> Int? {
        let query = "[out:json][timeout:5];way(around:\(overpassRadiusM),\(lat),\(lng))[highway][maxspeed];out tags 1;"
        guard
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)")
        else { return nil }
        guard let body = await httpGet(url) else { return nil }
        guard
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
            let elements = json["elements"] as? [[String: Any]],
            let first = elements.first,
            let tags = first["tags"] as? [String: Any],
            let maxspeedStr = tags["maxspeed"] as? String
        else { return nil }
        return firstIntMatch(in: maxspeedStr)
    }

    private func httpGet(_ url: URL) async -> Data? {
        var request = URLRequest(url: url, timeoutInterval: 5)
        // Works around pooled keep-alive sockets misbehaving across hosts hit back
        // to back (TomTom then Overpass) -- same defensive header as the Kotlin source.
        request.setValue("close", forHTTPHeaderField: "Connection")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            return data
        } catch {
            return nil
        }
    }

    private func firstIntMatch(in string: String) -> Int? {
        var result = ""
        for char in string {
            if char.isNumber {
                result.append(char)
            } else if !result.isEmpty {
                break
            }
        }
        return Int(result)
    }
}

private func haversineMeters(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
    let earthRadiusM = 6371000.0
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadiusM * c
}
