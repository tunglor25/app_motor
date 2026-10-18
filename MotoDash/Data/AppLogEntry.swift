import Foundation

enum LogCategory: String, CaseIterable {
    case all = "TẤT CẢ"
    case ble = "BLE"
    case kline = "K-LINE"
    case packet = "HEX"
    case audio = "AUDIO"
    case warn = "CẢNH BÁO"
}

struct AppLogEntry: Identifiable, Equatable {
    let id: Int64
    let timestamp: String
    let category: LogCategory
    let title: String
    let detail: String
    let isError: Bool
}
