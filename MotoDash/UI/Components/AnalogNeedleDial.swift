import SwiftUI

private let sweepDegrees: Double = 270
private let startDegrees: Double = -135

/// Simplified native port of the Kotlin source's ui/components/AnalogNeedleDial.kt
/// (classic.html's twin chrome-bezel analog needle dials) -- bezel gradient/brand
/// text/full tick set are cut for time, keeping the needle sweep and center
/// readout faithful.
struct AnalogNeedleDial: View {
    let ratio: Double
    let valueText: String
    var subText: String?
    let label: String
    let needleColor: Color

    private var angle: Double {
        startDegrees + min(max(ratio, 0), 1) * sweepDegrees
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(argb: 0xFF2A2A2A), lineWidth: 6)
                .padding(6)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                Path { path in
                    let cx = geo.size.width / 2
                    let cy = geo.size.height / 2
                    path.move(to: CGPoint(x: cx, y: cy))
                    path.addLine(to: CGPoint(x: cx, y: cy - size / 2 * 0.75))
                }
                .stroke(needleColor, style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round))
                .rotationEffect(.degrees(angle), anchor: .center)
            }

            VStack(spacing: 2) {
                Text(valueText)
                    .foregroundColor(.white)
                    .font(DashFont.rajdhani(28))
                if let subText {
                    Text(subText)
                        .foregroundColor(.dashDim)
                        .font(DashFont.shareTechMono(11))
                }
                Text(label)
                    .foregroundColor(.dashDim)
                    .font(DashFont.playfairItalic(11))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
