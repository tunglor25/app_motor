import Foundation

/// Thresholds/logic always stay in the ECU's native units (km/h, Celsius) -- only
/// display text converts. Exact port of the Kotlin source's UnitConversions.kt.
enum UnitConversions {
    static func speedText(_ kmh: Int?, unitSpeed: String) -> String {
        guard let kmh else { return "--" }
        if unitSpeed == "mph" {
            return String(Int((Double(kmh) * 0.621371).rounded()))
        }
        return String(kmh)
    }

    static func speedUnitLabel(_ unitSpeed: String) -> String {
        unitSpeed == "mph" ? "mph" : "km/h"
    }

    static func tempText(_ celsius: Int?, unitTemp: String) -> String {
        guard let celsius else { return "--" }
        if unitTemp == "f" {
            return String((celsius * 9) / 5 + 32)
        }
        return String(celsius)
    }

    static func tempUnitLabel(_ unitTemp: String) -> String {
        unitTemp == "f" ? "\u{00B0}F" : "\u{00B0}C"
    }
}
