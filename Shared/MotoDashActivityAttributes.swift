import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
public struct MotoDashActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var speedKmh: Int
        public var rpm: Int
        public var ectCelsius: Int
        public var batteryVolts: Double
        public var isBleConnected: Bool
        public var isEcuOnline: Bool
        public var isTripRecording: Bool
        public var tripDistanceKm: Double
        public var tripElapsedSec: Int

        public init(
            speedKmh: Int = 0,
            rpm: Int = 0,
            ectCelsius: Int = 0,
            batteryVolts: Double = 12.6,
            isBleConnected: Bool = false,
            isEcuOnline: Bool = false,
            isTripRecording: Bool = false,
            tripDistanceKm: Double = 0.0,
            tripElapsedSec: Int = 0
        ) {
            self.speedKmh = speedKmh
            self.rpm = rpm
            self.ectCelsius = ectCelsius
            self.batteryVolts = batteryVolts
            self.isBleConnected = isBleConnected
            self.isEcuOnline = isEcuOnline
            self.isTripRecording = isTripRecording
            self.tripDistanceKm = tripDistanceKm
            self.tripElapsedSec = tripElapsedSec
        }
    }

    public var bikeName: String

    public init(bikeName: String = "HONDA AIR BLADE 125") {
        self.bikeName = bikeName
    }
}
#endif

public struct MotoDashSharedSnapshot: Codable {
    public var speedKmh: Int
    public var rpm: Int
    public var ectCelsius: Int
    public var batteryVolts: Double
    public var isBleConnected: Bool
    public var isEcuOnline: Bool
    public var isTripRecording: Bool
    public var tripDistanceKm: Double
    public var tripElapsedSec: Int
    public var updatedAt: Date

    public init(
        speedKmh: Int = 0,
        rpm: Int = 0,
        ectCelsius: Int = 0,
        batteryVolts: Double = 12.6,
        isBleConnected: Bool = false,
        isEcuOnline: Bool = false,
        isTripRecording: Bool = false,
        tripDistanceKm: Double = 0.0,
        tripElapsedSec: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.speedKmh = speedKmh
        self.rpm = rpm
        self.ectCelsius = ectCelsius
        self.batteryVolts = batteryVolts
        self.isBleConnected = isBleConnected
        self.isEcuOnline = isEcuOnline
        self.isTripRecording = isTripRecording
        self.tripDistanceKm = tripDistanceKm
        self.tripElapsedSec = tripElapsedSec
        self.updatedAt = updatedAt
    }

    private static let storageKey = "motodash_widget_snapshot_v1"
    private static let appGroupId = "group.com.ab125.motodash"

    public static func save(_ snapshot: MotoDashSharedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        UserDefaults(suiteName: appGroupId)?.set(data, forKey: storageKey)
    }

    public static func load() -> MotoDashSharedSnapshot {
        if let groupData = UserDefaults(suiteName: appGroupId)?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(MotoDashSharedSnapshot.self, from: groupData) {
            return decoded
        }
        if let stdData = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(MotoDashSharedSnapshot.self, from: stdData) {
            return decoded
        }
        return MotoDashSharedSnapshot()
    }
}
