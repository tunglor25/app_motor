import SwiftUI

struct AirBladeDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    private let hondaRed = Color(argb: 0xFFE60012)
    private let lcdIceBlue = Color(argb: 0xFF7DF9FF)
    private let lcdAmber = Color(argb: 0xFFFFB300)

    var body: some View {
        let r = state.reading
        let rpm = r.rpm ?? 0
        let rpmRatio = min(max(Double(rpm) / 11000.0, 0), 1)
        ZStack {
            VStack(spacing: 8) {
                // Top Honda AirBlade LCD Header
                HStack {
                    HStack(spacing: 6) {
                        Rectangle().fill(hondaRed).frame(width: 4, height: 18)
                        Text("HONDA AIRBLADE 125 · SMART ECU")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(13))
                            .fontWeight(.bold)
                            .tracking(2)
                    }
                    Spacer()
                    if r.sideStandDown {
                        Text("CHÂN CHỐNG HẠ")
                            .foregroundColor(.black)
                            .font(DashFont.shareTechMono(10))
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(lcdAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text(r.ecuConnected ? "PGM-FI OK" : "K-LINE WAIT")
                        .foregroundColor(r.ecuConnected ? .dashGreen : lcdAmber)
                        .font(DashFont.shareTechMono(11))
                        .onTapGesture(perform: onConnectClick)
                    Button(action: onGearClick) {
                        Text("⚙").foregroundColor(lcdIceBlue).font(.system(size: 18))
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Segmented LCD Tachometer Arc Bar
                HStack(spacing: 4) {
                    ForEach(0..<22, id: \.self) { i in
                        let active = Double(i) / 22.0 < rpmRatio
                        let barColor: Color = i >= 17 ? hondaRed : lcdIceBlue
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active ? barColor : Color.white.opacity(0.07))
                            .frame(height: 14)
                    }
                }
                .padding(.horizontal, 16)

                // Main Negative LCD Panel
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        AbLcdTile(label: "VÒNG TUA MÁY", value: "\(rpm) RPM", color: lcdIceBlue)
                        AbLcdTile(label: "ĐIỆN ÁP BÌNH", value: r.battery.map { String(format: "%.1f V", $0) } ?? "--", color: (r.battery ?? 12.5) < 11.8 ? hondaRed : lcdIceBlue)
                        AbLcdTile(label: "BƯỚM GA (TPS)", value: r.tps.map { "\($0) %" } ?? "--", color: lcdAmber)
                    }
                    .frame(width: 155)

                    VStack(spacing: 2) {
                        Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(.white)
                            .font(DashFont.rajdhani(92, weight: .bold))
                            .textGlow(lcdIceBlue, radius: 14)
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed))
                            .foregroundColor(lcdIceBlue)
                            .font(DashFont.shareTechMono(14))
                            .tracking(3)
                        Text(String(format: "ODO TRIP: %.2f km", state.tripKm))
                            .foregroundColor(.dashTextSecondary)
                            .font(DashFont.shareTechMono(12))
                            .padding(.top, 4)
                            .onTapGesture {
                                if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(argb: 0xFF06152D).opacity(0.75))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(lcdIceBlue.opacity(0.35), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .trailing, spacing: 8) {
                        AbLcdTile(
                            label: "NƯỚC MÁT (ECT)",
                            value: r.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--",
                            color: (r.ect ?? 0) >= 100 ? hondaRed : lcdIceBlue
                        )
                        AbLcdTile(label: "PHUN XĂNG (Ti)", value: r.injectorTi.map { String(format: "%.2f ms", Double($0) / 1000.0) } ?? "--", color: lcdIceBlue)
                        AbLcdTile(label: "GÓC LỬA / O2", value: r.ignitionTiming.map { "\($0)° · " + (r.o2Voltage.map { String(format: "%.2fV", $0) } ?? "--") } ?? "--", color: lcdAmber)
                    }
                    .frame(width: 155)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity)
            }

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF0A1D3B), Color(argb: 0xFF030A17)], center: .center, startRadius: 0, endRadius: 550)
        )
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct AbLcdTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(9))
            Text(value)
                .foregroundColor(color)
                .font(DashFont.shareTechMono(16))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(argb: 0xFF06152D).opacity(0.8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
