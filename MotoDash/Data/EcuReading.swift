import Foundation

/// Live ECU values pushed over BLE. All fields start nil and stay nil until the
/// first real notification for that characteristic arrives -- never seed a
/// plausible-looking default (e.g. ect=85), the UI renders "--" for nil instead.
struct EcuReading: Equatable {
    var rpm: Int?
    var speed: Int?
    var ect: Int?
    var tps: Int?
    var battery: Float?
    var iat: Int?
    var o2Voltage: Float?
    /// true only once the ESP32 has actually completed a K-Line handshake with
    /// the ECU (distinct from "BLE connected" -- BLE can be connected while the
    /// bike's ignition is off or the handshake hasn't finished yet).
    var ecuConnected: Bool = false
    var dtcCodes: [String] = []
}
