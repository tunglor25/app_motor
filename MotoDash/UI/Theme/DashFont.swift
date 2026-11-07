import SwiftUI

// System rounded & geometric fonts with tabular monospaced digits (.monospacedDigit())
// ensure 100% native Vietnamese diacritics (no broken glyph fallback on accented letters)
// while keeping all numeric gauges and telemetry readouts strictly fixed-width.
enum DashFont {
    static func shareTechMono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    }

    static func orbitron(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded).monospacedDigit()
    }

    static func rajdhani(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    static func playfairItalic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic().monospacedDigit()
    }
}
