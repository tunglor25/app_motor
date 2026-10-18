import Foundation

/// Live ECU values pushed over BLE (supports 20-byte Dual-CRC telemetry packet).
struct EcuReading: Equatable {
    var rpm: Int?
    var speed: Int?
    var ect: Int?
    var tps: Int?
    var battery: Float?
    var iat: Int?
    var o2Voltage: Float?
    var ecuConnected: Bool = false
    var dtcCodes: [String] = []
    /// Goc danh lua som (°BTDC)
    var ignitionTiming: Int?
    /// Thoi gian phun xang (microseconds)
    var injectorTi: Int?
    /// Bitmask cong tac: Bit0 = Chan chong, Bit1 = De, Bit2 = Phanh
    var switches: Int = 0
    /// Thoi gian no may (giay)
    var runTimeSec: Int?
    /// Tai dong co uoc tinh (%)
    var engineLoad: Int?
    /// Chuoi HEX goi tin BLE/K-Line moi nhat
    var rawHex: String = ""
    /// Tong so goi tin da nhan
    var packetCount: Int64 = 0
    /// Tan so cap nhat (Hz)
    var packetHz: Float = 0.0

    var sideStandDown: Bool { (switches & 0x01) != 0 }
}
