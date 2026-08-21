import Foundation
import SwiftUI

// Thresholds read directly from the Kotlin source's ui/components/VitalsRow.kt
// (in turn race.html).
private func ectColor(_ ect: Int?) -> Color {
    guard let ect else { return .dashDim }
    if ect >= 110 { return .dashRed }
    if ect > 100 { return .dashAmber }
    return .white
}

private func battColor(_ batt: Float?) -> Color {
    guard let batt else { return .dashDim }
    if batt > 14.8 || batt < 11.5 { return .dashRed }
    if batt <= 12.0 { return .dashAmber }
    return .white
}

struct VitalsRow: View {
    let tps: Int?
    let battery: Float?
    let ect: Int?
    var unitTemp: String = "c"

    var body: some View {
        VStack {
            HStack {
                VitalBox(label: "TPS", value: tps.map { "\($0)" } ?? "--", unit: "%", valueColor: .white)
                VitalBox(label: "BATT", value: battery.map { String(format: "%.1f", $0) } ?? "--", unit: "V", valueColor: battColor(battery))
                VitalBox(
                    label: "ECT",
                    value: UnitConversions.tempText(ect, unitTemp: unitTemp),
                    unit: UnitConversions.tempUnitLabel(unitTemp),
                    valueColor: ectColor(ect)
                )
            }
            EctFillBar(ect: ect)
                .padding(.top, 6)
        }
    }
}

private struct VitalBox: View {
    let label: String
    let value: String
    let unit: String
    let valueColor: Color

    private var accentColor: Color {
        valueColor == .white ? Color.white.opacity(0.2) : valueColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(12))
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .foregroundColor(valueColor)
                    .font(DashFont.shareTechMono(28))
                Text(unit)
                    .foregroundColor(.dashDim)
                    .font(DashFont.shareTechMono(13))
                    .padding(.bottom, 3)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
        }
    }
}

private struct EctFillBar: View {
    let ect: Int?

    private var fraction: CGFloat {
        CGFloat(min(max(Double(ect ?? 0) / 120.0, 0), 1))
    }

    private var color: Color {
        (ect ?? 0) > 105 ? .dashRed : .dashGreen
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.08))
                Rectangle().fill(color)
                    .frame(width: geo.size.width * fraction)
                    .animation(.easeInOut(duration: 0.3), value: fraction)
            }
        }
        .frame(height: 3)
    }
}
