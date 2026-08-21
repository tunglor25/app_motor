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
}
