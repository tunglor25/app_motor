import SwiftUI

struct CrazyDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    private let nitroOrange = Color(argb: 0xFFFF5500)
    private let nitroLime = Color(argb: 0xFF39FF14)

    var body: some View {
        let r = state.reading
        let rpm = r.rpm ?? 0
        let rpmRatio = min(max(Double(rpm) / 12000.0, 0), 1)
        ZStack {
            VStack(spacing: 8) {
                HStack {
                    Text("🔥 NITRO OVERDRIVE // STAGE 3")
                        .foregroundColor(nitroOrange)
                        .font(DashFont.shareTechMono(13))
                        .fontWeight(.bold)
                        .tracking(2)
                    Spacer()
                    Button(action: onGearClick) {
                        Text("⚙").foregroundColor(nitroLime).font(.system(size: 18))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HStack(spacing: 16) {
                    ZStack {
                        SemicircularArcGauge(ratio: rpmRatio)
                        VStack(spacing: 2) {
                            Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                                .foregroundColor(nitroLime)
                                .font(DashFont.rajdhani(76, weight: .bold))
                                .textGlow(nitroLime, radius: 14)
                            Text("\(rpm) RPM")
                                .foregroundColor(nitroOrange)
                                .font(DashFont.shareTechMono(15))
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        NitroBar(label: "THROTTLE (TPS)", pct: Double(r.tps ?? 0) / 100.0, text: "\(r.tps ?? 0)%", color: nitroOrange)
                        NitroBar(label: "ENGINE LOAD", pct: Double(r.engineLoad ?? 0) / 100.0, text: "\(r.engineLoad ?? 0)%", color: nitroLime)
                        NitroBar(label: "COOLANT TEMP", pct: Double(r.ect ?? 0) / 120.0, text: "\(r.ect ?? 0)°C", color: .dashCyan)
                        HStack {
                            Text("BATT: \(r.battery.map { String(format: "%.1fV", $0) } ?? "--")")
                                .foregroundColor(.white)
                                .font(DashFont.shareTechMono(12))
                            Spacer()
                            Text("IGN: \(r.ignitionTiming.map { "\($0)°" } ?? "--")")
                                .foregroundColor(nitroOrange)
                                .font(DashFont.shareTechMono(12))
                        }
                    }
                    .frame(width: 200)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF1F0800), Color(argb: 0xFF050200)], center: .center, startRadius: 0, endRadius: 500)
        )
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct NitroBar: View {
    let label: String
    let pct: Double
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).foregroundColor(.dashTextSecondary).font(DashFont.shareTechMono(10))
                Spacer()
                Text(text).foregroundColor(color).font(DashFont.shareTechMono(12)).fontWeight(.bold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(0, min(1, pct)) * geo.size.width)
                }
            }
            .frame(height: 8)
        }
    }
}
