import SwiftUI

// Bundled offline (this dashboard needs to work with no signal on a bike) --
// see Resources/Fonts/. Share Tech Mono for mono readouts (all themes),
// Orbitron for the race theme's bold numerics.
//
// Rajdhani (daily theme) and Playfair Display Italic (classic theme) from the
// Kotlin source are NOT bundled in this iOS port (only the two fonts listed
// above shipped in Resources/Fonts) -- daily/classic screens fall back to
// close system-font equivalents (.rounded / .serif italic) below instead.
enum DashFont {
    static func shareTechMono(_ size: CGFloat) -> Font {
        .custom("Share Tech Mono", size: size)
    }

    static func orbitron(_ size: CGFloat) -> Font {
        .custom("Orbitron", size: size)
    }

    /// Stand-in for the Kotlin source's Rajdhani (daily theme) -- not bundled here.
    static func rajdhani(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Stand-in for the Kotlin source's Playfair Display Italic (classic theme) -- not bundled here.
    static func playfairItalic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }
}
