import SwiftUI
import UIKit

/// Root navigation host -- mirrors the Kotlin source's MainActivity.kt NavHost
/// wiring (screen graph, autoConnect/wakeLock/fullscreen side effects, and the
/// theme switch that picks which dashboard screen renders).
struct ContentView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var mediaSessionReader: MediaSessionReader
    @StateObject private var locationPermissionManager = LocationPermissionManager()

    @State private var path: [Route] = []
    @State private var notificationAccessGranted = false

    var body: some View {
        NavigationStack(path: $path) {
            DashboardContainerView(
                state: viewModel.state,
                mediaSessionReader: mediaSessionReader,
                onSelClick: viewModel.toggleLapTimer,
                onConnectClick: startConnectFlow,
                onGearClick: { path.append(.settings) },
                onTripShortClick: viewModel.startTripRecording,
                onTripLongPress: viewModel.stopTripRecordingAndSave,
                onSetShortClick: viewModel.toggleLapTimer,
                onSetLongPress: viewModel.resetAll,
                onTripSaved: { id in
                    viewModel.consumeSavedTripId()
                    path.append(.tripResult(id))
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .statusBar(hidden: viewModel.state.settings.fullscreen)
        .onAppear {
            notificationAccessGranted = mediaSessionReader.isAuthorized()
            if viewModel.state.settings.autoConnect {
                startConnectFlow()
            }
        }
        .onChange(of: viewModel.state.settings.wakeLock) { newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onChange(of: viewModel.state.settings.autoConnect) { newValue in
            if newValue { startConnectFlow() }
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .settings:
            SettingsScreen(
                settings: viewModel.state.settings,
                connectionState: viewModel.state.connectionState,
                notificationAccessGranted: notificationAccessGranted,
                onSetTheme: viewModel.setTheme,
                onSetUnitSpeed: viewModel.setUnitSpeed,
                onSetUnitTemp: viewModel.setUnitTemp,
                onSetSpeedWarnEnabled: viewModel.setSpeedWarnEnabled,
                onSetShiftWarnEnabled: viewModel.setShiftWarnEnabled,
                onSetRpmWarnVal: viewModel.setRpmWarnVal,
                onSetAutoConnect: viewModel.setAutoConnect,
                onSetWakeLock: viewModel.setWakeLock,
                onSetFullscreen: viewModel.setFullscreen,
                onSetDemoMode: viewModel.setDemoMode,
                onSetAutoHideMusic: viewModel.setAutoHideMusic,
                onDisconnect: viewModel.disconnectBle,
                onReconnect: startConnectFlow,
                onNavigateTripHistory: { path.append(.tripHistory) },
                onNavigateDiagnostics: { path.append(.diagnostics) },
                onClearAllTrips: viewModel.clearAllTrips,
                onOpenNotificationAccessSettings: requestMusicAuthorization,
                onBack: goBack
            )
        case .diagnostics:
            DiagnosticsScreen(reading: viewModel.state.reading, unitTemp: viewModel.state.settings.unitTemp, onBack: goBack)
        case .tripHistory:
            TripHistoryScreen(
                tripRepository: viewModel.tripRepository,
                onOpenTrip: { id in path.append(.tripResult(id)) },
                onBack: goBack
            )
        case .tripResult(let id):
            TripResultScreen(tripId: id, tripRepository: viewModel.tripRepository, onBack: goBack)
        }
    }

    private func goBack() {
        if !path.isEmpty { path.removeLast() }
    }

    private func startConnectFlow() {
        locationPermissionManager.requestWhenInUseIfNeeded()
        viewModel.connect()
    }

    private func requestMusicAuthorization() {
        mediaSessionReader.requestAuthorization { granted in
            notificationAccessGranted = granted
        }
    }
}

/// Picks which dashboard theme renders, mirroring MainActivity.kt's `when (state.settings.theme)`.
private struct DashboardContainerView: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onSelClick: () -> Void
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onSetShortClick: () -> Void
    let onSetLongPress: () -> Void
    let onTripSaved: (String) -> Void

    var body: some View {
        switch state.settings.theme {
        case "daily":
            DailyDashboardScreen(
                state: state,
                mediaSessionReader: mediaSessionReader,
                onConnectClick: onConnectClick,
                onGearClick: onGearClick,
                onTripShortClick: onTripShortClick,
                onTripLongPress: onTripLongPress,
                onTripSaved: onTripSaved
            )
        case "classic":
            ClassicDashboardScreen(
                state: state,
                mediaSessionReader: mediaSessionReader,
                onConnectClick: onConnectClick,
                onGearClick: onGearClick,
                onTripShortClick: onTripShortClick,
                onTripLongPress: onTripLongPress,
                onTripSaved: onTripSaved
            )
        default:
            DashboardScreen(
                state: state,
                mediaSessionReader: mediaSessionReader,
                onSelClick: onSelClick,
                onConnectClick: onConnectClick,
                onGearClick: onGearClick,
                onTripShortClick: onTripShortClick,
                onTripLongPress: onTripLongPress,
                onSetShortClick: onSetShortClick,
                onSetLongPress: onSetLongPress,
                onTripSaved: onTripSaved
            )
        }
    }
}
