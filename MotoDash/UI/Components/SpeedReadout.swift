import SwiftUI

struct SpeedReadout: View {
    let speed: Int?
    var unitSpeed: String = "kmh"

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(UnitConversions.speedText(speed, unitSpeed: unitSpeed))
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(72))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .textGlow(Color.white.opacity(0.5), radius: 20)
            Text(UnitConversions.speedUnitLabel(unitSpeed))
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(18))
        }
    }
}
