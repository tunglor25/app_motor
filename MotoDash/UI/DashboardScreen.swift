import SwiftUI

struct DashboardScreen: View {
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
        ZStack {
            VStack(spacing: 0) {
                TopBar(lapText: state.lapText, tripKm: state.tripKm, onGearClick: onGearClick)
                TachometerGauge(rpm: state.reading.rpm)
                    .padding(.horizontal, 12)
                ConnectionStatusRow(connectionState: state.connectionState, onConnectClick: onConnectClick)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }
                VStack {
                    Spacer()
                    SpeedReadout(speed: state.reading.speed, unitSpeed: state.settings.unitSpeed)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                VitalsRow(tps: state.reading.tps, battery: state.reading.battery, ect: state.reading.ect, unitTemp: state.settings.unitTemp)
                    .padding(.horizontal, 16)
                ButtonRow(
                    lapRunning: state.lapRunning,
                    isTripRecording: state.isTripRecording,
                    onSelClick: onSelClick,
                    onTripShortClick: onTripShortClick,
                    onTripLongPress: onTripLongPress,
                    onSetShortClick: onSetShortClick,
                    onSetLongPress: onSetLongPress
                )
            }

            VStack {
                Spacer()
                HStack {
                    MusicWidget(reader: mediaSessionReader)
                    Spacer()
                }
            }
            .padding(16)

            VStack {
                HStack {
                    Spacer()
                    SpeedLimitBadge(speedLimitKmh: state.speedLimitKmh, currentSpeed: state.reading.speed, enabled: state.settings.speedWarnEnabled)
                }
                Spacer()
            }
            .padding(.top, 92)
            .padding(.trailing, 16)

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)

            if state.resetFlash {
                Color.white.opacity(0.5).ignoresSafeArea()
            }
        }
        .dashboardBackground()
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct ConnectionStatusRow: View {
    let connectionState: BleConnectionState
    let onConnectClick: () -> Void

    private var labelAndColor: (String, Color) {
        switch connectionState {
        case .idle: return ("Cham de ket noi ECU", .dashDim)
        case .scanning: return ("Dang tim ECU...", .dashAmber)
        case .connecting: return ("Dang ket noi...", .dashAmber)
        case .connected: return ("Da ket noi", .dashGreen)
        case .disconnected: return ("Mat ket noi -- dang tu ket noi lai", .dashRed)
        case .error(let message): return ("Loi: \(message)", .dashRed)
        }
    }

    var body: some View {
        let (label, color) = labelAndColor
        Text(label)
            .foregroundColor(color)
            .font(DashFont.shareTechMono(11))
            .tracking(1)
            .textGlow(color, radius: 8)
            .onTapGesture(perform: onConnectClick)
    }
}
