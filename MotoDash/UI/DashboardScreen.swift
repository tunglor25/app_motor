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
            VStack(spacing: 2) {
                TopBar(
                    lapText: state.lapText,
                    tripKm: state.tripKm,
                    brandLogo: state.settings.brandLogo,
                    onGearClick: onGearClick
                )
                TachometerGauge(rpm: state.reading.rpm)
                    .padding(.horizontal, 12)
                ConnectionStatusRow(connectionState: state.connectionState, onConnectClick: onConnectClick)
                    .padding(.horizontal, 16)
                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }
                Spacer(minLength: 0)
                SpeedReadout(speed: state.reading.speed, unitSpeed: state.settings.unitSpeed)
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
                VitalsRow(tps: state.reading.tps, battery: state.reading.battery, ect: state.reading.ect, unitTemp: state.settings.unitTemp)
                    .padding(.horizontal, 12)
                ButtonRow(
                    lapRunning: state.lapRunning,
                    isTripRecording: state.isTripRecording,
                    onSelClick: onSelClick,
                    onTripShortClick: onTripShortClick,
                    onTripLongPress: onTripLongPress,
                    onSetShortClick: onSetShortClick,
                    onSetLongPress: onSetLongPress,
                    onGearClick: onGearClick
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomLeading) {
                MusicWidget(reader: mediaSessionReader)
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                SpeedLimitBadge(speedLimitKmh: state.speedLimitKmh, currentSpeed: state.reading.speed, enabled: state.settings.speedWarnEnabled)
                    .padding(.top, 52)
                    .padding(.trailing, 16)
                    .allowsHitTesting(false)
            }

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)

            if state.resetFlash {
                Color.white.opacity(0.5).ignoresSafeArea().allowsHitTesting(false)
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
        case .idle: return ("▶ Chạm để kết nối ECU", .dashCyan)
        case .scanning: return ("Đang tìm ECU...", .dashAmber)
        case .connecting: return ("Đang kết nối...", .dashAmber)
        case .connected: return ("✓ Đã kết nối BLE", .dashGreen)
        case .disconnected: return ("Mất kết nối -- đang tự kết nối lại", .dashRed)
        case .error(let message): return ("Lỗi: \(message) (Chạm thử lại)", .dashRed)
        }
    }

    var body: some View {
        let (label, color) = labelAndColor
        Button(action: onConnectClick) {
            Text(label)
                .foregroundColor(color)
                .font(DashFont.shareTechMono(11))
                .tracking(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
