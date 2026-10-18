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
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text("CYBER // AB-2077")
                        .foregroundColor(cyberYellow)
                        .font(DashFont.shareTechMono(13))
                        .tracking(2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(r.ecuConnected ? "K-LINE LOCKED" : "SCANNING LINK")
                        .foregroundColor(r.ecuConnected ? neonCyan : neonMagenta)
                        .font(DashFont.shareTechMono(11))
                        .onTapGesture(perform: onConnectClick)
                    Button(action: onGearClick) {
                        Text("⚙").foregroundColor(neonCyan).font(.system(size: 18))
                    }
                    .padding(.leading, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Segmented Cyber RPM Bar
                HStack(spacing: 3) {
                    ForEach(0..<30, id: \.self) { i in
                        let active = Double(i) / 30.0 < ratio
                        let segColor: Color = i >= 24 ? neonMagenta : (i >= 18 ? cyberYellow : neonCyan)
                        Rectangle()
                            .fill(active ? segColor : Color.white.opacity(0.08))
                            .frame(height: 18)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    // Left telemetry column
                    VStack(alignment: .leading, spacing: 8) {
                        CyberHudBox(label: "RPM", value: "\(rpm)", accent: neonCyan)
                        CyberHudBox(label: "TPS THROTTLE", value: r.tps.map { "\($0)%" } ?? "--", accent: cyberYellow)
                        CyberHudBox(label: "IGN TIMING", value: r.ignitionTiming.map { "\($0)°" } ?? "--", accent: neonMagenta)
                    }
                    .frame(width: 140)

                    // Center giant speed readout
                    VStack(spacing: 0) {
                        Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(neonCyan)
                            .font(DashFont.rajdhani(96, weight: .bold))
                            .textGlow(neonCyan, radius: 16)
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed) + " · NIGHT CITY")
                            .foregroundColor(neonMagenta)
                            .font(DashFont.shareTechMono(13))
                            .tracking(3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Right telemetry column
                    VStack(alignment: .trailing, spacing: 8) {
                        CyberHudBox(
                            label: "COOLANT ECT",
                            value: r.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--",
                            accent: (r.ect ?? 0) >= 100 ? neonMagenta : neonCyan
                        )
                        CyberHudBox(label: "BATTERY", value: r.battery.map { String(format: "%.1fV", $0) } ?? "--", accent: cyberYellow)
                        CyberHudBox(label: "INJECTOR Ti", value: r.injectorTi.map { String(format: "%.1fms", Double($0) / 1000.0) } ?? "--", accent: neonCyan)
                    }
                    .frame(width: 140)
                }
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity)

                HStack {
                    Text(state.isTripRecording ? "● REC TRIP (\(String(format: "%.1f km", state.tripKm)))" : "▶ START TRIP (\(String(format: "%.1f km", state.tripKm)))")
                        .foregroundColor(cyberYellow)
                        .font(DashFont.shareTechMono(12))
                        .onTapGesture {
                            if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                        }
                    Spacer()
                    if r.sideStandDown {
                        Text("⚠ SIDE STAND DOWN")
                            .foregroundColor(neonMagenta)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            LinearGradient(colors: [Color(argb: 0xFF090014), Color(argb: 0xFF020008)], startPoint: .top, endPoint: .bottom)
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
                .font(DashFont.shareTechMono(18))
                .fontWeight(.bold)
                .textGlow(accent, radius: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.5), lineWidth: 1))
    }
}
