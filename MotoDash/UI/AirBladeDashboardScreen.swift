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
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Image("logo_\(state.settings.brandLogo)")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                        Rectangle().fill(hondaRed).frame(width: 4, height: 16)
                        Text("HONDA AIRBLADE 125 · SMART ECU")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                            .tracking(1)
                    }
                    Spacer()
                    if r.sideStandDown {
                        Text("CHÂN CHỐNG HẠ")
                            .foregroundColor(.black)
                            .font(DashFont.shareTechMono(10))
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(lcdAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Button(action: onConnectClick) {
                        Text(r.ecuConnected ? "PGM-FI OK" : "K-LINE WAIT")
                            .foregroundColor(r.ecuConnected ? .dashGreen : lcdAmber)
                            .font(DashFont.shareTechMono(11))
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
                        .foregroundColor(lcdIceBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(lcdIceBlue.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(lcdIceBlue.opacity(0.6), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 6)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                HStack(spacing: 4) {
                    ForEach(0..<22, id: \.self) { i in
                        let active = Double(i) / 22.0 < rpmRatio
                        let barColor: Color = i >= 17 ? hondaRed : lcdIceBlue
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active ? barColor : Color.white.opacity(0.07))
                            .frame(height: 12)
                    }
                }
                .padding(.horizontal, 12)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        AbLcdTile(label: "VÒNG TUA MÁY", value: "\(rpm) RPM", color: lcdIceBlue)
                        AbLcdTile(label: "ĐIỆN ÁP BÌNH", value: r.battery.map { String(format: "%.1f V", $0) } ?? "--", color: (r.battery ?? 12.5) < 11.8 ? hondaRed : lcdIceBlue)
                        AbLcdTile(label: "BƯỚM GA (TPS)", value: r.tps.map { "\($0) %" } ?? "--", color: lcdAmber)
                    }
                    .frame(width: 145)

                    VStack(spacing: 2) {
                        Text(UnitConversions.speedText(r.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(.white)
                            .font(DashFont.rajdhani(72, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .textGlow(lcdIceBlue, radius: 12)
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed))
                            .foregroundColor(lcdIceBlue)
                            .font(DashFont.shareTechMono(13))
                            .tracking(2)
                        Button(action: {
                            if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                        }) {
                            Text(String(format: "ODO TRIP: %.2f km", state.tripKm))
                                .foregroundColor(.dashTextSecondary)
                                .font(DashFont.shareTechMono(11))
                                .padding(.top, 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(argb: 0xFF06152D).opacity(0.75))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(lcdIceBlue.opacity(0.35), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .trailing, spacing: 6) {
                        AbLcdTile(
                            label: "NƯỚC MÁT (ECT)",
                            value: r.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--",
                            color: (r.ect ?? 0) >= 100 ? hondaRed : lcdIceBlue
                        )
                        AbLcdTile(label: "PHUN XĂNG (Ti)", value: r.injectorTi.map { String(format: "%.2f ms", Double($0) / 1000.0) } ?? "--", color: lcdIceBlue)
                        AbLcdTile(label: "GÓC LỬA / O2", value: r.ignitionTiming.map { "\($0)° · " + (r.o2Voltage.map { String(format: "%.2fV", $0) } ?? "--") } ?? "--", color: lcdAmber)
                    }
                    .frame(width: 145)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .frame(maxHeight: .infinity)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            ShiftFlashOverlay(rpm: r.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF0A1D3B), Color(argb: 0xFF030A17)], center: .center, startRadius: 0, endRadius: 550)
                .ignoresSafeArea()
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
                .font(DashFont.shareTechMono(14))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color(argb: 0xFF06152D).opacity(0.8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
