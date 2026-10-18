import SwiftUI

struct CyberDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    private let neonMagenta = Color(argb: 0xFFFF007F)
    private let neonCyan = Color(argb: 0xFF00F0FF)
    private let cyberYellow = Color(argb: 0xFFFCEE09)

    var body: some View {
        let r = state.reading
        let rpm = r.rpm ?? 0
        let ratio = min(max(Double(rpm) / 12000.0, 0), 1)
        ZStack {
            VStack(spacing: 6) {
                HStack {
                    Image("logo_\(state.settings.brandLogo)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Text("CYBER // AB-2077")
                        .foregroundColor(cyberYellow)
                        .font(DashFont.shareTechMono(13))
                        .tracking(2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: onConnectClick) {
                        Text(r.ecuConnected ? "K-LINE LOCKED" : "SCANNING LINK")
                            .foregroundColor(r.ecuConnected ? neonCyan : neonMagenta)
                            .font(DashFont.shareTechMono(11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Button(action: onGearClick) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("CÀI ĐẶT")
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(neonCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(neonCyan.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(neonCyan.opacity(0.6), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 6)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                HStack(spacing: 3) {
                    ForEach(0..<30, id: \.self) { i in
                        let active = Double(i) / 30.0 < ratio
                        let segColor: Color = i >= 24 ? neonMagenta : (i >= 18 ? cyberYellow : neonCyan)
                        Rectangle()
                            .fill(active ? segColor : Color.white.opacity(0.08))
                            .frame(height: 14)
                    }
                }
                .padding(.horizontal, 12)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        CyberHudBox(label: "RPM", value: "\(rpm)", accent: neonCyan)
                        CyberHudBox(label: "TPS THROTTLE", value: r.tps.map { "\($0)%" } ?? "--", accent: cyberYellow)
                        CyberHudBox(label: "IGN TIMING", value: r.ignitionTiming.map { "\($0)°" } ?? "--", accent: neonMagenta)
                    }
                    .frame(width: 135)

                    VStack(spacing: 0) {
                        Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(neonCyan)
                            .font(DashFont.rajdhani(76, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .textGlow(neonCyan, radius: 14)
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed) + " · NIGHT CITY")
                            .foregroundColor(neonMagenta)
                            .font(DashFont.shareTechMono(12))
                            .tracking(2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(alignment: .trailing, spacing: 6) {
                        CyberHudBox(
                            label: "COOLANT ECT",
                            value: r.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--",
                            accent: (r.ect ?? 0) >= 100 ? neonMagenta : neonCyan
                        )
                        CyberHudBox(label: "BATTERY", value: r.battery.map { String(format: "%.1fV", $0) } ?? "--", accent: cyberYellow)
                        CyberHudBox(label: "INJECTOR Ti", value: r.injectorTi.map { String(format: "%.1fms", Double($0) / 1000.0) } ?? "--", accent: neonCyan)
                    }
                    .frame(width: 135)
                }
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)

                HStack {
                    Button(action: {
                        if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                    }) {
                        Text(state.isTripRecording ? "● REC TRIP (\(String(format: "%.1f km", state.tripKm)))" : "▶ START TRIP (\(String(format: "%.1f km", state.tripKm)))")
                            .foregroundColor(cyberYellow)
                            .font(DashFont.shareTechMono(11))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    if r.sideStandDown {
                        Text("⚠ SIDE STAND DOWN")
                            .foregroundColor(neonMagenta)
                            .font(DashFont.shareTechMono(11))
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            LinearGradient(colors: [Color(argb: 0xFF090014), Color(argb: 0xFF020008)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct CyberHudBox: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(accent.opacity(0.8))
                .font(DashFont.shareTechMono(9))
                .tracking(1)
            Text(value)
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(15))
                .fontWeight(.bold)
                .textGlow(accent, radius: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color.white.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.5), lineWidth: 1))
    }
}
