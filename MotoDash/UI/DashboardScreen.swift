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
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let r = state.reading
            let rpm = r.rpm ?? 0
            let rpmRatio = min(max(Double(rpm) / 12000.0, 0), 1)

            ZStack {
                VStack(spacing: isPortrait ? 8 : 2) {
                    TopBar(
                        lapText: state.lapText,
                        tripKm: state.isTripRecording ? state.liveTripStats.distanceKm : state.tripKm,
                        brandLogo: state.settings.brandLogo,
                        onGearClick: onGearClick
                    )
                    TachometerGauge(rpm: r.rpm)
                        .padding(.horizontal, 12)
                        .frame(height: isPortrait ? 72 : 62)
                    ConnectionStatusRow(connectionState: state.connectionState, onConnectClick: onConnectClick)
                        .padding(.horizontal, 16)
                    if state.isTripRecording {
                        TripRecordingBar(stats: state.liveTripStats, onStop: onTripLongPress)
                    }

                    Spacer(minLength: 0)

                    if isPortrait {
                        // Portrait Center Cyber Ring + Live Telemetry Grid (eliminates empty vertical void)
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 14)
                                .frame(width: 228, height: 228)

                            Circle()
                                .trim(from: 0, to: max(0.02, rpmRatio * 0.78))
                                .stroke(
                                    AngularGradient(
                                        colors: [.dashCyan, .dashGreen, .dashAmber, .dashRed],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                )
                                .rotationEffect(.degrees(130))
                                .frame(width: 228, height: 228)
                                .shadow(color: Color.dashCyan.opacity(0.35), radius: 10)

                            Circle()
                                .stroke(Color.dashCyan.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .frame(width: 192, height: 192)

                            VStack(spacing: 2) {
                                Text(r.ecuConnected ? "ECU ACTIVE" : "RACE TELEMETRY")
                                    .foregroundColor(.dashCyan)
                                    .font(DashFont.shareTechMono(10))
                                    .tracking(1.5)
                                Text("\(r.speed ?? 0)")
                                    .foregroundColor(.white)
                                    .font(DashFont.orbitron(76))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .textGlow(Color.dashCyan.opacity(0.45), radius: 18)
                                Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed).uppercased())
                                    .foregroundColor(.dashTextSecondary)
                                    .font(DashFont.shareTechMono(13))
                                    .tracking(2)
                                Text("\(rpm) RPM")
                                    .foregroundColor(rpm >= 9000 ? .dashRed : .dashAmber)
                                    .font(DashFont.shareTechMono(13))
                                    .fontWeight(.bold)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)

                        Spacer(minLength: 0)

                        // Extra Portrait Telemetry Row (IAT, IGN, INJ Ti)
                        HStack(spacing: 8) {
                            RaceMiniCard(
                                label: "IAT",
                                value: r.iat.map { "\(UnitConversions.tempText($0, unitTemp: state.settings.unitTemp))\(UnitConversions.tempUnitLabel(state.settings.unitTemp))" } ?? "--",
                                color: .dashCyan
                            )
                            RaceMiniCard(
                                label: "IGN TIMING",
                                value: r.ignitionTiming.map { "\($0)°" } ?? "--",
                                color: .dashAmber
                            )
                            RaceMiniCard(
                                label: "INJECTOR Ti",
                                value: r.injectorTi.map { String(format: "%.1fms", Double($0) / 1000.0) } ?? "--",
                                color: .dashGreen
                            )
                        }
                        .padding(.horizontal, 12)
                    } else {
                        SpeedReadout(speed: r.speed ?? 0, unitSpeed: state.settings.unitSpeed)
                            .padding(.horizontal, 16)
                        Spacer(minLength: 0)
                    }

                    VitalsRow(tps: r.tps, battery: r.battery, ect: r.ect, unitTemp: state.settings.unitTemp)
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
                    SpeedLimitBadge(speedLimitKmh: state.speedLimitKmh, currentSpeed: r.speed, enabled: state.settings.speedWarnEnabled)
                        .padding(.top, 52)
                        .padding(.trailing, 16)
                        .allowsHitTesting(false)
                }

                ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)

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
}

private struct RaceMiniCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(9.5))
                .tracking(1)
            Text(value)
                .foregroundColor(color)
                .font(DashFont.shareTechMono(15))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
