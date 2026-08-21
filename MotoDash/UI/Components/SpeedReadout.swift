import SwiftUI

struct SpeedReadout: View {
    let speed: Int?
    var unitSpeed: String = "kmh"

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(UnitConversions.speedText(speed, unitSpeed: unitSpeed))
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(96))
                .textGlow(Color.white.opacity(0.5), radius: 30)
            Text(UnitConversions.speedUnitLabel(unitSpeed))
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(20))
                .padding(.bottom, 16)
        }
        .padding(.vertical, 8)
    }
}
