import SwiftUI

struct SuperbikeDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    private let ducatiRed = Color(argb: 0xFFFF1E1E)
    private let trackAmber = Color(argb: 0xFFFFB800)

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let r = state.reading
            let rpm = r.rpm ?? 0
            let rpmRatio = min(max(Double(rpm) / 12000.0, 0), 1)

            let leftCard = VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image("logo_\(state.settings.brandLogo)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                    Text("TELEMETRY")
                        .foregroundColor(ducatiRed)
                        .font(DashFont.shareTechMono(10))
                        .fontWeight(.bold)
                }
                SbRow(label: "RPM", value: "\(rpm)")
                SbRow(label: "LAP", value: state.lapText)
                Button(action: {
                    if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                }) {
                    HStack {
                        Text(state.isTripRecording ? "⏹ DỪNG" : "▶ TRIP")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(10))
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(format: "%.1f km", state.isTripRecording ? state.liveTripStats.distanceKm : state.tripKm))
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(10.5))
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(state.isTripRecording ? ducatiRed : trackAmber.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                SbRow(label: "LOAD", value: r.engineLoad.map { "\($0)%" } ?? "--")
            }
            .padding(10)
            .background(Color.dashCardBackground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dashCardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            let rightCard = VStack(alignment: .leading, spacing: 6) {
                Text("ENGINE VITALS")
                    .foregroundColor(trackAmber)
                    .font(DashFont.shareTechMono(10))
                    .fontWeight(.bold)
                SbRow(label: "ECT", value: r.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--")
                SbRow(label: "TPS", value: r.tps.map { "\($0)%" } ?? "--")
                SbRow(label: "BATT", value: r.battery.map { String(format: "%.1fV", $0) } ?? "--")
                SbRow(label: "INJ", value: r.injectorTi.map { String(format: "%.1fms", Double($0) / 1000.0) } ?? "--")
            }
            .padding(10)
            .background(Color.dashCardBackground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dashCardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            let centerSpeed = VStack(spacing: 2) {
                Text("CVT DRIVE")
                    .foregroundColor(trackAmber)
                    .font(DashFont.shareTechMono(11))
                    .tracking(2)
                Text(UnitConversions.speedText(r.speed ?? 0, unitSpeed: state.settings.unitSpeed))
                    .foregroundColor(.white)
                    .font(DashFont.rajdhani(isPortrait ? 88 : 76, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .textGlow(ducatiRed, radius: 14)
                Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed))
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(13))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ZStack {
                VStack(spacing: isPortrait ? 10 : 6) {
                    HStack(spacing: 4) {
                        ForEach(0..<16, id: \.self) { i in
                            let active = Double(i) / 16.0 < rpmRatio
                            let ledColor: Color = i >= 12 ? ducatiRed : (i >= 8 ? trackAmber : .dashGreen)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(active ? ledColor : Color.white.opacity(0.14))
                                .frame(height: 12)
                        }
                        Button(action: onGearClick) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("CÀI ĐẶT")
                                    .font(DashFont.shareTechMono(11.5))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ducatiRed.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ducatiRed, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    if state.isTripRecording {
                        TripRecordingBar(stats: state.liveTripStats, onStop: onTripLongPress)
                    }

                    if isPortrait {
                        centerSpeed
                        HStack(alignment: .top, spacing: 10) {
                            leftCard.frame(maxWidth: .infinity)
                            rightCard.frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    } else {
                        HStack(spacing: 12) {
                            leftCard.frame(width: 150)
                            centerSpeed
                            rightCard.frame(width: 150)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)

                ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
            }
            .background(Color(argb: 0xFF08080A).ignoresSafeArea())
            .onChange(of: state.savedTripId) { newValue in
                if let id = newValue { onTripSaved(id) }
            }
        }
    }
}

private struct SbRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.dashTextSecondary).font(DashFont.shareTechMono(11))
            Spacer()
            Text(value).foregroundColor(.white).font(DashFont.shareTechMono(13)).fontWeight(.bold)
        }
    }
}
