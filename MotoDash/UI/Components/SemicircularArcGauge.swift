import SwiftUI
import UIKit

private let startAngleDegrees: Double = 165
private let sweepAngleDegrees: Double = 210
private let trackColor = Color(argb: 0xFF20242C)

/// Simplified native port of the Kotlin source's ui/components/SemicircularArcGauge.kt
/// (daily.html's semicircular RPM arc, horseshoe open at the bottom, 210deg
/// sweep). The web version bakes a fixed cyan->amber->red gradient along the
/// whole track; here the lit portion is a single interpolated color instead of
/// a true baked gradient -- a deliberate simplification, close enough visually
/// for a secondary theme.
struct SemicircularArcGauge: View {
    let ratio: Double

    private var clamped: Double { min(max(ratio, 0), 1) }

    private var liveColor: Color {
        if clamped < 0.65 {
            return Self.lerpColor(.dashCyan, .dashAmber, clamped / 0.65)
        }
        return Self.lerpColor(.dashAmber, .dashRed, min(max((clamped - 0.65) / 0.35, 0), 1))
    }

    var body: some View {
        GeometryReader { geo in
            let strokeWidth = min(geo.size.width, geo.size.height) * 0.09
            Path { path in
                path.addArc(
                    center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                    radius: min(geo.size.width, geo.size.height) / 2 - strokeWidth / 2,
                    startAngle: .degrees(startAngleDegrees),
                    endAngle: .degrees(startAngleDegrees + sweepAngleDegrees),
                    clockwise: false
                )
            }
            .stroke(trackColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            Path { path in
                path.addArc(
                    center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                    radius: min(geo.size.width, geo.size.height) / 2 - strokeWidth / 2,
                    startAngle: .degrees(startAngleDegrees),
                    endAngle: .degrees(startAngleDegrees + sweepAngleDegrees * clamped),
                    clockwise: false
                )
            }
            .stroke(liveColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        }
        .aspectRatio(1.4, contentMode: .fit)
    }

    private static func lerpColor(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ua = UIColor(a)
        let ub = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        ua.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        ub.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let clampedT = CGFloat(min(max(t, 0), 1))
        return Color(
            red: Double(ar + (br - ar) * clampedT),
            green: Double(ag + (bg - ag) * clampedT),
            blue: Double(ab + (bb - ab) * clampedT),
            opacity: Double(aa + (ba - aa) * clampedT)
        )
    }
}
