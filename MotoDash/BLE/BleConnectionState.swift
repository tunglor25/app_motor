import Foundation

enum BleConnectionState: Equatable {
    case idle
    case scanning
    case connecting
    case connected
    case disconnected
    case error(String)
}
