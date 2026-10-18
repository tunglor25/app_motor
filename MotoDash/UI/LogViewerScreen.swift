import SwiftUI
import UIKit

struct LogViewerScreen: View {
    let logs: [AppLogEntry]
    let reading: EcuReading
    let connectionState: BleConnectionState
    let logRawPackets: Bool
    let onSetLogRawPackets: (Bool) -> Void
    let onClearLogs: () -> Void
    let onBack: () -> Void

    @State private var selectedCategory: LogCategory = .all
    @State private var copiedToast = false

    private var filteredLogs: [AppLogEntry] {
        if selectedCategory == .all { return logs }
        return logs.filter { $0.category == selectedCategory }
    }

    private var bleStatusText: (String, Color) {
        switch connectionState {
        case .connected: return ("CONNECTED", .dashGreen)
        case .connecting, .scanning: return ("SCANNING", .dashAmber)
        default: return ("OFFLINE", .dashRed)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RacingStripe()
                ScreenHeader(title: "NHẬT KÝ K-LINE & BLE", onBack: onBack)
                    .padding(.leading, 12)
            }

            // Status bar
            HStack(spacing: 8) {
                LogStatChip(label: "BLE", value: bleStatusText.0, color: bleStatusText.1)
                LogStatChip(label: "K-LINE", value: reading.ecuConnected ? "ONLINE" : "WAIT", color: reading.ecuConnected ? .dashGreen : .dashAmber)
                LogStatChip(label: "GÓI TIN", value: "\(reading.packetCount)", color: .dashCyan)
                LogStatChip(label: "TỐC ĐỘ", value: String(format: "%.1f Hz", reading.packetHz), color: .dashCyan)
            }

            if !reading.rawHex.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GÓI TIN HEX MỚI NHẤT (20-BYTE DUAL-CRC)")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(10))
                        .tracking(1)
                    Text(reading.rawHex)
                        .foregroundColor(.dashCyan)
                        .font(DashFont.shareTechMono(12))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.dashCardBackground)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dashCyan.opacity(0.35), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Category filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(LogCategory.allCases, id: \.self) { cat in
                        let active = selectedCategory == cat
                        Text(cat.rawValue)
                            .foregroundColor(active ? .black : .dashTextSecondary)
                            .font(DashFont.shareTechMono(11))
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(active ? Color.dashCyan : Color.dashCardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(active ? Color.dashCyan : Color.dashCardBorder, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { selectedCategory = cat }
                    }
                }
            }

            // Controls row
            HStack(spacing: 8) {
                Button(action: { onSetLogRawPackets(!logRawPackets) }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(logRawPackets ? Color.dashGreen : Color.dashTextSecondary)
                            .frame(width: 8, height: 8)
                        Text(logRawPackets ? "LIVE HEX: BẬT" : "LIVE HEX: 3S/LẦN")
                            .foregroundColor(logRawPackets ? .dashGreen : .white)
                            .font(DashFont.shareTechMono(11))
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.dashCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(logRawPackets ? Color.dashGreen : Color.dashCardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                Button(action: {
                    let dump = filteredLogs.map { "[\($0.timestamp)] [\($0.category.rawValue)] \($0.title) \($0.detail)" }.joined(separator: "\n")
                    UIPasteboard.general.string = dump
                    copiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedToast = false }
                }) {
                    Text(copiedToast ? "ĐÃ CHÉP ✓" : "SAO CHÉP")
                        .foregroundColor(.dashCyan)
                        .font(DashFont.shareTechMono(11))
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.dashCardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan.opacity(0.4), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onClearLogs) {
                    Text("XÓA LOG")
                        .foregroundColor(.dashRed)
                        .font(DashFont.shareTechMono(11))
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.dashCardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashRed.opacity(0.4), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Log list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if filteredLogs.isEmpty {
                        Text("Chưa có nhật ký nào trong mục này.")
                            .foregroundColor(.dashTextSecondary)
                            .font(DashFont.shareTechMono(13))
                            .padding(.top, 24)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredLogs) { entry in
                            LogEntryCard(entry: entry)
                        }
                    }
                }
            }
        }
        .padding(16)
        .dashboardBackground()
    }
}

private struct LogStatChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(9))
            Text(value)
                .foregroundColor(color)
                .font(DashFont.shareTechMono(12))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct LogEntryCard: View {
    let entry: AppLogEntry

    private var catColor: Color {
        if entry.isError { return .dashRed }
        switch entry.category {
        case .ble: return .dashCyan
        case .kline: return .dashGreen
        case .packet: return Color(argb: 0xFFB388FF)
        case .audio: return .dashAmber
        case .warn: return .dashRed
        case .all: return .white
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(entry.timestamp)
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(10))
                Text(entry.category.rawValue)
                    .foregroundColor(.black)
                    .font(DashFont.shareTechMono(9))
                    .fontWeight(.bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(catColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(entry.title)
                    .foregroundColor(entry.isError ? .dashRed : .white)
                    .font(DashFont.shareTechMono(12))
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
            }
            if !entry.detail.isEmpty {
                Text(entry.detail)
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
            }
        }
        .padding(10)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(entry.isError ? Color.dashRed.opacity(0.5) : Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
