import CoreLocation
import Foundation

struct LiveTripStats: Equatable {
    var distanceKm: Double = 0.0
    var elapsedMs: Int64 = 0
    var maxSpeedGpsKmh: Double = 0.0
}

/// Combines GPS updates with an in-memory TripRecorderSession, persisting the
/// finished trip via TripRepository. Mirrors the Kotlin source's
/// data/GpsTripRecorder.kt start()/stop()/addEcuSample() flow, using
/// CLLocationManager where Android used FusedLocationProviderClient.
@MainActor
final class GpsTripRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let tripRepository: TripRepository
    private var session: TripRecorderSession?

    @Published private(set) var isRecording = false
    @Published private(set) var liveStats = LiveTripStats()

    init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
    }

    func start() {
        guard !isRecording else { return }
        let activeSession = TripRecorderSession()
        activeSession.start()
        session = activeSession
        isRecording = true
        liveStats = LiveTripStats()

        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        // Declared in UIBackgroundModes ("location") so the trip keeps recording
        // while the app is backgrounded/screen is off.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }

    func addEcuSample(speed: Int?, rpm: Int?, ect: Int?) {
        session?.addEcuSample(speed: speed, rpm: rpm, ect: ect)
    }

    func stopAndSave() async -> String? {
        guard let activeSession = session else { return nil }
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        session = nil
        isRecording = false
        let trip = activeSession.stop()
        await tripRepository.save(trip)
        return trip.id
    }

    func cancel() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        session = nil
        isRecording = false
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            guard let activeSession = session else { return }
            let speedKmh = max(location.speed, 0) * 3.6
            let timestampMs = Int64(location.timestamp.timeIntervalSince1970 * 1000)
            activeSession.addGpsPoint(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                speedKmh: speedKmh,
                timestamp: timestampMs,
                accuracyM: location.horizontalAccuracy
            )
            liveStats = LiveTripStats(
                distanceKm: activeSession.totalDistanceKm,
                elapsedMs: Int64(Date().timeIntervalSince1970 * 1000) - activeSession.startedAt,
                maxSpeedGpsKmh: activeSession.maxSpeedGpsKmh
            )
        }
    }
}
