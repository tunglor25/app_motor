import SwiftUI

// Palette read directly from the Kotlin source's ui/theme/Color.kt, which itself
// was read from www/race.html + settings.html's :root CSS custom properties
// (dark theme only). Do not change without checking that source first.
extension Color {
    /// ARGB hex initializer, e.g. 0xFF2BE7FF (alpha, red, green, blue).
    init(argb: UInt32) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    static let dashCyan = Color(argb: 0xFF2BE7FF)
    static let dashRed = Color(argb: 0xFFFF2130)
    static let dashAmber = Color(argb: 0xFFFFB703)
    static let dashGreen = Color(argb: 0xFF00FF66)
    static let dashDim = Color(argb: 0x73FFFFFF) // rgba(255,255,255,0.45)
    static let dashBackground = Color(argb: 0xFF050608)

    // settings.html's --card / --card-border exactly -- cards are genuinely
    // translucent in the source, not solid. What makes the source not read as
    // flat is the textured background behind them plus glow/letter-spacing
    // details, not opaque card fills -- see DashboardBackground.swift.
    static let dashCardBackground = Color(argb: 0x0AFFFFFF) // rgba(255,255,255,0.04)
    static let dashCardBorder = Color(argb: 0x14FFFFFF) // rgba(255,255,255,0.08)
    static let dashSurfaceRaised = Color(argb: 0xFF1A2029) // toggle-off track, needs to read as a distinct control
    static let dashDivider = Color(argb: 0x14FFFFFF)
    static let dashTextSecondary = Color(argb: 0x73FFFFFF) // --text-dim: rgba(255,255,255,0.45)
}
