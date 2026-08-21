import CoreLocation
import Foundation

/// iOS equivalent of the Kotlin source's permissions/BlePermissions.kt. Bluetooth
/// permission is prompted automatically by CoreBluetooth the first time
/// CBCentralManager scans (gated by NSBluetoothAlwaysUsageDescription in
/// Info.plist); only location needs an explicit request call on iOS.
@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestWhenInUseIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
