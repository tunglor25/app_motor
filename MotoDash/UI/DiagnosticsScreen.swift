import Foundation
import SwiftUI

// The web app's diagnostics.html originally also showed MAP/injector-pulse
// cards, both fake and already removed. IAT + O2 + DTC are the real extra
// fields the firmware provides beyond what the dashboard shows.
struct DiagnosticsScreen: View {
    let reading: EcuReading
    var unitTemp: String = "c"
    let onBack: () -> Void
    var onClearDtc: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                RacingStripe()
                ScreenHeader(title: "CH\u{1EA8}N \u{0110}O\u{00C1}N", onBack: onBack)
                    .padding(.leading, 12)
            }

            VStack {
                DiagCard(
                    systemImage: "thermometer",
                    label: "NHI\u{1EC6}T \u{0110}\u{1ED8} KH\u{00CD} N\u{1EA0}P (IAT)",
                    value: reading.iat.map { UnitConversions.tempText($0, unitTemp: unitTemp) + UnitConversions.tempUnitLabel(unitTemp) } ?? "--"
                )
                DiagCard(
                    systemImage: "bolt.fill",
                    label: "\u{0110}I\u{1EC6}N \u{00C1}P C\u{1EA2}M BI\u{1EBF}N OXY (O2)",
                    value: reading.o2Voltage.map { String(format: "%.2fV", $0) } ?? "--"
                )
                DtcCard(dtcCodes: reading.dtcCodes, onClearDtc: onClearDtc)
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding(16)
        .dashboardBackground()
    }
}

// Ma loi DTC that tu Mode 03, dang chuan OBD-II (P0135, P0115...) -- khong
// phai ma nhap nhay den kieu Honda doi cu. Rong = khong co loi (xanh); co
// ma = liet ke tung ma (do) + nut xoa (Mode 04, cham 2 lan de xac nhan tranh
// xoa nham).
private struct DtcCard: View {
    let dtcCodes: [String]
    let onClearDtc: () -> Void
    @State private var confirmClear = false

    var body: some View {
        let hasDtc = !dtcCodes.isEmpty
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    Circle().fill((hasDtc ? Color.dashRed : Color.dashGreen).opacity(0.1))
                    Image(systemName: hasDtc ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(hasDtc ? .dashRed : .dashGreen)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("M\u{00C3} L\u{1ED6}I (DTC)")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                        .tracking(1)
                    Text(hasDtc ? dtcCodes.joined(separator: ", ") : "Kh\u{00F4}ng c\u{00F3} m\u{00E3} l\u{1ED7}i")
                        .foregroundColor(hasDtc ? .dashRed : .dashGreen)
                        .font(DashFont.shareTechMono(hasDtc ? 20 : 18))
                        .fontWeight(.bold)
                }
                .padding(.leading, 14)

                Spacer()
            }

            if hasDtc {
                Text(confirmClear ? "CH\u{1EA0}M L\u{1EA6}N N\u{1EEE}A \u{0110}\u{1EC2} X\u{00C1}C NH\u{1EAD}N X\u{00D3}A" : "X\u{00D3}A M\u{00C3} L\u{1ED6}I (Mode 04)")
                    .foregroundColor(confirmClear ? .dashRed : .dashTextSecondary)
                    .font(DashFont.shareTechMono(12))
                    .tracking(1)
                    .fontWeight(.bold)
                    .padding(.top, 14)
                    .onTapGesture {
                        if confirmClear {
                            onClearDtc()
                            confirmClear = false
                        } else {
                            confirmClear = true
                        }
                    }
            }
        }
        .padding(18)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(hasDtc ? Color.dashRed.opacity(0.4) : Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 6)
    }
}

private struct DiagCard: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            ZStack {
                Circle().fill(Color.dashCyan.opacity(0.1))
                Image(systemName: systemImage)
                    .foregroundColor(.dashCyan)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
                    .tracking(1)
                Text(value)
                    .foregroundColor(.white)
                    .font(DashFont.shareTechMono(30))
                    .fontWeight(.bold)
                    .textGlow(.dashCyan, radius: 10)
            }
            .padding(.leading, 14)

            Spacer()
        }
        .padding(18)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 6)
    }
}
