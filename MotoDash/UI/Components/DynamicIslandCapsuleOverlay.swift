import SwiftUI

struct DynamicIslandCapsuleOverlay: View {
    let state: DashboardUiState
    @ObservedObject var guardian: BackgroundGuardianManager
    let onStartTrip: () -> Void
    let onStopTrip: () -> Void
    let onOpenTripHistory: () -> Void

    @State private var manualExpanded = false
    @State private var pulse = false

    private var isExpanded: Bool {
        manualExpanded || guardian.justReturnedFromBackground
    }

    var body: some View {
        VStack(spacing: 6) {
            // Compact Dynamic Island Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(state.isTripRecording ? Color.dashRed : Color.dashGreen)
                    .frame(width: 8, height: 8)
                    .opacity(pulse ? 0.35 : 1.0)

                Image(systemName: state.isTripRecording ? "record.circle.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(state.isTripRecording ? .dashRed : .dashCyan)

                Text(pillTitle)
                    .foregroundColor(.white)
                    .font(DashFont.shareTechMono(10.5))
                    .fontWeight(.bold)
                    .lineLimit(1)

                if state.isTripRecording {
                    Button(action: onStopTrip) {
                        Text("⏹ DỪNG")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(10))
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dashRed)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(argb: 0xF206090F))
            )
            .overlay(
                Capsule()
                    .stroke(
                        state.isTripRecording ? Color.dashRed.opacity(0.85) : Color.dashCyan.opacity(0.55),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: (state.isTripRecording ? Color.dashRed : Color.dashCyan).opacity(0.35), radius: 10)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    manualExpanded.toggle()
                    if !manualExpanded {
                        guardian.justReturnedFromBackground = false
                    }
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("⚡ MOTODASH ĐANG CHẠY NGẦM BẢO VỆ XE")
                            .foregroundColor(.dashGreen)
                            .font(DashFont.shareTechMono(11))
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                manualExpanded = false
                                guardian.justReturnedFromBackground = false
                            }
                        }) {
                            Text("ĐÓNG ✕")
                                .foregroundColor(.dashTextSecondary)
                                .font(DashFont.shareTechMono(10))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("• Tự giữ kết nối BLE ECU + Chống báo nhầm quên tắt khóa 5 lớp kể cả khi khóa màn hình.\n• Hỗ trợ Dynamic Island Live Activity & Widget ngoài màn hình chính.")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(10))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        if state.isTripRecording {
                            Button(action: onStopTrip) {
                                Text("⏹ DỪNG & LƯU TRIP (\(String(format: "%.2f km", state.liveTripStats.distanceKm)))")
                                    .foregroundColor(.white)
                                    .font(DashFont.shareTechMono(11))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.dashRed)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: onStartTrip) {
                                Text("▶ BẮT ĐẦU HÀNH TRÌNH")
                                    .foregroundColor(.dashCyan)
                                    .font(DashFont.shareTechMono(11))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.dashCyan.opacity(0.16))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            manualExpanded = false
                            onOpenTripHistory()
                        }) {
                            Text("🗺️ LỊCH SỬ")
                                .foregroundColor(.white)
                                .font(DashFont.shareTechMono(11))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(argb: 0xF8080C14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.dashCyan.opacity(0.65), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.75), radius: 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var pillTitle: String {
        if state.isTripRecording {
            let totalSec = Int(state.liveTripStats.elapsedMs / 1000)
            let m = totalSec / 60
            let s = totalSec % 60
            return String(format: "REC %.2fkm · %02d:%02d", state.liveTripStats.distanceKm, m, s)
        }
        if guardian.justReturnedFromBackground {
            return "VẪN ĐANG CHẠY NGẦM ✓"
        }
        if state.connectionState == .connected {
            return state.reading.ecuConnected ? "NGẦM: K-LINE + 5 LỚP" : "NGẦM: BLE + 5 LỚP"
        }
        return "CHẠY NGẦM BẢO VỆ: BẬT"
    }
}
