import SwiftUI

/// CSS `text-shadow: 0 0 <blurPx> <color>` equivalent for SwiftUI Text/View.
/// Applied twice (matching the Kotlin port's guidance) so the glow reads with
/// the same intensity as Compose's Shadow(blurRadius:).
extension View {
    func textGlow(_ color: Color, radius: CGFloat = 12) -> some View {
        self
            .shadow(color: color, radius: radius, x: 0, y: 0)
            .shadow(color: color, radius: radius / 2, x: 0, y: 0)
    }
}
