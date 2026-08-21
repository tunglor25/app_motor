import Foundation
import SwiftUI

// The web app's diagnostics.html originally also showed MAP/injector-pulse/DTC
// cards, all fake and already removed. IAT + O2 are the only real extra fields
// the firmware provides beyond what the dashboard shows.
struct DiagnosticsScreen: View {
    let reading: EcuReading
    var unitTemp: String = "c"
    let onBack: () -> Void

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
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding(16)
        .dashboardBackground()
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
