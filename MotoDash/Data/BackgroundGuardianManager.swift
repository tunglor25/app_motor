import Foundation
import UIKit
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class BackgroundGuardianManager: ObservableObject {
    static let shared = BackgroundGuardianManager()

    @Published var justReturnedFromBackground: Bool = false
    @Published var isLiveActivityActive: Bool = false

    private var lastWidgetReloadTime: TimeInterval = 0
    private var lastLiveActivityUpdateTime: TimeInterval = 0
    private var latestState = DashboardUiState()

    private init() {
        requestNotificationPermission()
        setupLifecycleObservers()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleDidEnterBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWillEnterForeground()
            }
        }
    }

    func syncState(_ state: DashboardUiState) {
        latestState = state
        let now = ProcessInfo.processInfo.systemUptime

        let isBleConnected = (state.connectionState == .connected) && !state.settings.demoMode
        let isEcuOnline = state.reading.ecuConnected || state.settings.demoMode
        let distKm = state.isTripRecording ? state.liveTripStats.distanceKm : state.tripKm
        let elapsedSec = Int(state.liveTripStats.elapsedMs / 1000)

        let snapshot = MotoDashSharedSnapshot(
            speedKmh: state.reading.speed ?? 0,
            rpm: state.reading.rpm ?? 0,
            ectCelsius: state.reading.ect ?? 0,
            batteryVolts: state.reading.battery ?? 12.6,
            isBleConnected: isBleConnected,
            isEcuOnline: isEcuOnline,
            isTripRecording: state.isTripRecording,
            tripDistanceKm: distKm,
            tripElapsedSec: elapsedSec,
            updatedAt: Date()
        )
        MotoDashSharedSnapshot.save(snapshot)

        if now - lastLiveActivityUpdateTime >= 1.0 || state.isTripRecording {
            lastLiveActivityUpdateTime = now
            updateOrStartLiveActivity(with: snapshot)
        }

        if now - lastWidgetReloadTime >= 10.0 {
            lastWidgetReloadTime = now
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    private func updateOrStartLiveActivity(with snap: MotoDashSharedSnapshot) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let contentState = MotoDashActivityAttributes.ContentState(
                speedKmh: snap.speedKmh,
                rpm: snap.rpm,
                ectCelsius: snap.ectCelsius,
                batteryVolts: snap.batteryVolts,
                isBleConnected: snap.isBleConnected,
                isEcuOnline: snap.isEcuOnline,
                isTripRecording: snap.isTripRecording,
                tripDistanceKm: snap.tripDistanceKm,
                tripElapsedSec: snap.tripElapsedSec
            )

            if let existing = Activity<MotoDashActivityAttributes>.activities.first {
                isLiveActivityActive = true
                Task {
                    await existing.update(using: contentState)
                }
            } else {
                let attrs = MotoDashActivityAttributes(bikeName: "HONDA AIR BLADE 125")
                if let _ = try? Activity.request(attributes: attrs, contentState: contentState, pushType: nil) {
                    isLiveActivityActive = true
                }
            }
        }
        #endif
    }

    private func handleDidEnterBackground() {
        syncState(latestState)
        postBackgroundGuardianNotification(for: latestState)
    }

    private func handleWillEnterForeground() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["motodash.background.guardian"])
        justReturnedFromBackground = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            self.justReturnedFromBackground = false
        }
    }

    private func postBackgroundGuardianNotification(for state: DashboardUiState) {
        let content = UNMutableNotificationContent()
        let dist = state.isTripRecording ? state.liveTripStats.distanceKm : state.tripKm
        if state.isTripRecording {
            content.title = "🔴 MotoDash Đang Ghi Hành Trình Ngầm"
            content.body = String(
                format: "Đã ghi %.2f km · Max %d km/h. Kết nối BLE ECU & 5 lớp chống báo nhầm quên tắt khóa vẫn đang bảo vệ xe.",
                dist,
                Int(state.liveTripStats.maxSpeedGpsKmh)
            )
        } else {
            let bleTxt = (state.connectionState == .connected) ? "Đã kết nối BLE ECU ✓" : "Đang canh kết nối BLE tự động"
            content.title = "🛡️ MotoDash Đang Chạy Ngầm Bảo Vệ Xe"
            content.body = "\(bleTxt) · Hệ thống chống báo nhầm quên tắt khóa 5 lớp & Telemetry vẫn đang hoạt động ngầm."
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "motodash.background.guardian", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
