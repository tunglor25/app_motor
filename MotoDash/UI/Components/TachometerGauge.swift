import SwiftUI
import UIKit

/// Custom 56-segment trapezoid tachometer, a faithful port of the Kotlin
/// source's ui/components/TachometerGauge.kt (itself a port of race.html's
/// hand-built SVG gauge) -- not a generic arc, the curved baseline and
/// per-segment growing stroke width are the point of the design.
struct TachometerGauge: View {
    let rpm: Int?

    private let segments = 56
    private let maxRpm = 14000
    private let viewW: CGFloat = 400
    private let viewH: CGFloat = 90
    private let gap: CGFloat = 1.0
    private let slant: CGFloat = 3.0
    private let unlitColor = Color(argb: 0xFF1E1E24)
    private let labelSteps = [0, 2, 4, 6, 8, 10, 12, 14]

    @State private var bootProgress: Double = 0
    @State private var bootDone = false

    private var step: CGFloat { 368.0 / CGFloat(segments) }

    var body: some View {
        Canvas { context, size in
            let litCount = bootDone ? realLitCount : Int(bootProgress.rounded())
            drawGauge(context: context, size: size, litCount: litCount)
        }
        .aspectRatio(viewW / viewH, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .task { await runBootAnimation() }
    }

    private var realLitCount: Int {
        let safeRpm = min(max(rpm ?? 0, 0), maxRpm)
        let ratio = Double(safeRpm) / Double(maxRpm)
        return min(max(Int((ratio * Double(segments)).rounded()), 0), segments)
    }

    // Boot sweep-in/hold/sweep-out, matching race.html's load animation, before
    // settling into real RPM-driven rendering.
    private func runBootAnimation() async {
        let sweepInSteps = 30
        for i in 0...sweepInSteps {
            bootProgress = Double(segments) * Double(i) / Double(sweepInSteps)
            try? await Task.sleep(nanoseconds: 224_000_000 / UInt64(sweepInSteps))
        }
        try? await Task.sleep(nanoseconds: 800_000_000)
        let sweepOutSteps = 30
        for i in 0...sweepOutSteps {
            bootProgress = Double(segments) * (1 - Double(i) / Double(sweepOutSteps))
            try? await Task.sleep(nanoseconds: 168_000_000 / UInt64(sweepOutSteps))
        }
        bootProgress = 0
        bootDone = true
    }

    // Curve baseline read directly from race.html's curveY(x): flat at 68 below
    // x=90, flat at 28 above x=330, linear ramp between.
    private func curveY(_ x: CGFloat) -> CGFloat {
        if x <= 90 { return 68 }
        if x >= 330 { return 28 }
        return 68 - ((x - 90) / 240) * 40
    }

    private func segmentColor(_ ratio: Double) -> Color {
        if ratio <= 0 { return .dashCyan }
        if ratio < 0.6 {
            return Self.lerpColor(.dashCyan, .dashAmber, ratio / 0.6)
        }
        return Self.lerpColor(.dashAmber, .dashRed, min(max((ratio - 0.6) / 0.4, 0), 1))
    }

    private func drawGauge(context: GraphicsContext, size: CGSize, litCount: Int) {
        let scaleX = size.width / viewW
        let scaleY = size.height / viewH

        for i in 0..<segments {
            let x1 = 16 + CGFloat(i) * step
            let x2 = 16 + CGFloat(i + 1) * step - gap
            let strokeWidth = 6 + (CGFloat(i) / CGFloat(segments - 1)) * 16
            let yc1 = curveY(x1)
            let yc2 = curveY(x2)
            let halfSw = strokeWidth / 2

            var path = Path()
            path.move(to: CGPoint(x: (x1 - slant) * scaleX, y: (yc1 - halfSw) * scaleY))
            path.addLine(to: CGPoint(x: (x2 - slant) * scaleX, y: (yc2 - halfSw) * scaleY))
            path.addLine(to: CGPoint(x: (x2 + slant) * scaleX, y: (yc2 + halfSw) * scaleY))
            path.addLine(to: CGPoint(x: (x1 + slant) * scaleX, y: (yc1 + halfSw) * scaleY))
            path.closeSubpath()

            let isLit = i < litCount
            let color = isLit ? segmentColor(Double(i) / Double(segments - 1)) : unlitColor

            if isLit {
                context.drawLayer { layerContext in
                    layerContext.addFilter(.shadow(color: color.opacity(0.55), radius: 5))
                    layerContext.fill(path, with: .color(color))
                }
            } else {
                context.fill(path, with: .color(color))
            }
        }

        for stepValue in labelSteps {
            let x = 16 + (CGFloat(stepValue) * 1000 / CGFloat(maxRpm)) * 368
            let y = curveY(x) - 12
            let labelColor: Color = stepValue >= 12 ? .dashRed : Color(argb: 0xFF888888)
            let text = Text("\(stepValue)")
                .font(.system(size: 8 * scaleY))
                .foregroundColor(labelColor)
            context.draw(text, at: CGPoint(x: x * scaleX, y: y * scaleY), anchor: .center)
        }
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
