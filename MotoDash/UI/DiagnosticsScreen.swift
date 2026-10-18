import Foundation
import SwiftUI

struct DiagnosticsScreen: View {
    let reading: EcuReading
    var unitTemp: String = "c"
    let onBack: () -> Void
    var onClearDtc: () -> Void = {}
    var onNavigateLogs: () -> Void = {}

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RacingStripe()
                    ScreenHeader(title: "CHẨN ĐOÁN ECU K-LINE", onBack: onBack)
                        .padding(.leading, 12)
                    Spacer()
                    Button(action: onNavigateLogs) {
                        Text("NHẬT KÝ HEX ›")
                            .foregroundColor(.dashCyan)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dashCardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan.opacity(0.5), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Connection banner
                HStack {
                    Circle()
                        .fill(reading.ecuConnected ? Color.dashGreen : Color.dashAmber)
                        .frame(width: 10, height: 10)
                    Text(reading.ecuConnected ? "K-LINE ISO 14230-4 ĐÃ KẾT NỐI · BẢNG 0x10 (20-BYTE)" : "ĐANG CHỜ PHẢN HỒI K-LINE TỪ ECU HONDA...")
                        .foregroundColor(reading.ecuConnected ? .dashGreen : .dashAmber)
                        .font(DashFont.shareTechMono(11))
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "%.1f Hz", reading.packetHz))
                        .foregroundColor(.dashCyan)
                        .font(DashFont.shareTechMono(11))
                }
                .padding(12)
                .background(Color.dashCardBackground)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dashCardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // 10-parameter grid
                LazyVGrid(columns: columns, spacing: 10) {
                    DiagParamTile(label: "VÒNG TUA (RPM)", value: reading.rpm.map { "\($0) rpm" } ?? "--", color: .dashCyan)
                    DiagParamTile(label: "TỐC ĐỘ XE (VSS)", value: reading.speed.map { "\($0) km/h" } ?? "--", color: .dashCyan)
                    DiagParamTile(
                        label: "NƯỚC MÁT (ECT)",
                        value: reading.ect.map { UnitConversions.tempText($0, unitTemp: unitTemp) + UnitConversions.tempUnitLabel(unitTemp) } ?? "--",
                        color: (reading.ect ?? 0) >= 100 ? .dashRed : .dashGreen
                    )
                    DiagParamTile(
                        label: "KHÍ NẠP (IAT)",
                        value: reading.iat.map { UnitConversions.tempText($0, unitTemp: unitTemp) + UnitConversions.tempUnitLabel(unitTemp) } ?? "--",
                        color: .dashCyan
                    )
                    DiagParamTile(label: "BƯỚM GA (TPS)", value: reading.tps.map { "\($0) %" } ?? "--", color: .dashAmber)
                    DiagParamTile(label: "ĐIỆN ÁP BÌNH", value: reading.battery.map { String(format: "%.2f V", $0) } ?? "--", color: .dashGreen)
                    DiagParamTile(label: "CẢM BIẾN OXY (O2)", value: reading.o2Voltage.map { String(format: "%.2f V", $0) } ?? "--", color: .dashCyan)
                    DiagParamTile(label: "GÓC ĐÁNH LỬA", value: reading.ignitionTiming.map { "\($0)° BTDC" } ?? "--", color: .dashAmber)
                    DiagParamTile(label: "THỜI GIAN PHUN", value: reading.injectorTi.map { String(format: "%.2f ms", Double($0) / 1000.0) } ?? "--", color: .dashCyan)
                    DiagParamTile(
                        label: "CHÂN CHỐNG / TẢI",
                        value: reading.engineLoad.map { (reading.sideStandDown ? "HẠ CHỐNG · " : "GẠT LÊN · ") + "\($0)%" } ?? "--",
                        color: reading.sideStandDown ? .dashRed : .dashGreen
                    )
                }

                DtcCard(dtcCodes: reading.dtcCodes, onClearDtc: onClearDtc)

                if !reading.rawHex.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RAW TELEMETRY FRAME (#\(reading.packetCount))")
                            .foregroundColor(.dashTextSecondary)
                            .font(DashFont.shareTechMono(10))
                        Text(reading.rawHex)
                            .foregroundColor(.dashCyan)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.dashCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dashCardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .dashboardBackground()
    }
}

private struct DiagParamTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(10))
                .tracking(1)
            Text(value)
                .foregroundColor(color)
                .font(DashFont.shareTechMono(20))
                .fontWeight(.bold)
                .textGlow(color, radius: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DtcCard: View {
    let dtcCodes: [String]
    let onClearDtc: () -> Void
    @State private var confirmClear = false

    var body: some View {
        let hasDtc = !dtcCodes.isEmpty
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    Circle().fill((hasDtc ? Color.dashRed : Color.dashGreen).opacity(0.1))
                    Image(systemName: hasDtc ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(hasDtc ? .dashRed : .dashGreen)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MÃ LỖI ECU (DTC MODE 03)")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                        .tracking(1)
                    Text(hasDtc ? dtcCodes.joined(separator: ", ") : "Không có mã lỗi")
                        .foregroundColor(hasDtc ? .dashRed : .dashGreen)
                        .font(DashFont.shareTechMono(hasDtc ? 18 : 16))
                        .fontWeight(.bold)
                }
                .padding(.leading, 12)

                Spacer()
            }

            if hasDtc {
                Text(confirmClear ? "CHẠM LẦN NỮA ĐỂ XÁC NHẬN XÓA" : "XÓA MÃ LỖI (Mode 04)")
                    .foregroundColor(confirmClear ? .dashRed : .dashTextSecondary)
                    .font(DashFont.shareTechMono(12))
                    .tracking(1)
                    .fontWeight(.bold)
                    .padding(.top, 12)
                    .onTapGesture {
                        if confirmClear {
                            onClearDtc()
                            confirmClear = false
                        } else {
                            confirmClear = true
                        }
                    }
            }
        }
        .padding(14)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(hasDtc ? Color.dashRed.opacity(0.4) : Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
