import SwiftUI

/// Exact port of the Kotlin source's ui/components/DashboardBackground.kt: solid
/// #050608, a -45deg diagonal hatch (3% white, 2pt stripe / 10pt period), a
/// radial blue-tinted glow centered top, and an inset vignette darkening the edges.
private struct DashboardBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color.dashBackground
                RadialGradient(
                    colors: [Color(argb: 0xCC001428), Color(argb: 0x99030304), Color(argb: 0xF2030304)],
                    center: UnitPoint(x: 0.5, y: 0.2),
                    startRadius: 0,
                    endRadius: max(w, h) * 0.9
                )
                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
                    context.translateBy(x: cx, y: cy)
                    context.rotate(by: .degrees(-45))
                    context.translateBy(x: -cx, y: -cy)

                    let diagW = size.width * 2.5
                    let diagH = size.height * 2.5
                    let period: CGFloat = 10
                    var y = -diagH
                    while y < diagH {
                        var path = Path()
                        path.move(to: CGPoint(x: -diagW, y: y))
                        path.addLine(to: CGPoint(x: diagW, y: y))
                        context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 2)
                        y += period
                    }
                }
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.5)],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(w, h) * 0.75
                )
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func dashboardBackground() -> some View {
        self.background(DashboardBackgroundView())
    }
}
