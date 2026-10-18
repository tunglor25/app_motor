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
            VStack(spacing: 6) {
                HStack {
                    Text("🔥 NITRO OVERDRIVE // STAGE 3")
                        .foregroundColor(nitroOrange)
                        .font(DashFont.shareTechMono(12))
                        .fontWeight(.bold)
                        .tracking(2)
                    Spacer()
                    Button(action: onGearClick) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("CÀI ĐẶT")
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(nitroLime)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(nitroLime.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(nitroLime.opacity(0.6), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                HStack(spacing: 16) {
                    ZStack {
                        SemicircularArcGauge(ratio: rpmRatio)
                            .frame(maxWidth: 260, maxHeight: 165)
                        VStack(spacing: 2) {
                            Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                                .foregroundColor(nitroLime)
                                .font(DashFont.rajdhani(64, weight: .bold))
                                .minimumScaleFactor(0.5)
                                .textGlow(nitroLime, radius: 14)
                            Text("\(rpm) RPM")
                                .foregroundColor(nitroOrange)
                                .font(DashFont.shareTechMono(14))
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
                    .frame(width: 190)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF1F0800), Color(argb: 0xFF050200)], center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
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
