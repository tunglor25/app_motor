import SwiftUI

struct DynamicIslandCapsuleOverlay: View {
    let state: DashboardUiState
    @ObservedObject var guardian: BackgroundGuardianManager
    let onStartTrip: () -> Void
    let onStopTrip: () -> Void
    let onOpenTripHistory: () -> Void

    @State private var pulse = false

    private var accentColor: Color {
        if state.isTripRecording {
            return .dashRed
        }
        if state.connectionState == .connected {
            return .dashGreen
        }
        return .dashCyan
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let isPortrait = geo.size.height > geo.size.width

            if isPortrait && topInset >= 44 {
                ZStack(alignment: .top) {
                    if topInset >= 51 {
                        // Hardware Dynamic Island perimeter neon ring (exact iPhone 14 Pro / 15 / 16 cutout)
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(pulse ? 0.95 : 0.45),
                                        accentColor.opacity(pulse ? 0.35 : 0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 126, height: 37)
                            .shadow(color: accentColor.opacity(pulse ? 0.65 : 0.25), radius: 6)
                            .padding(.top, 11)
                    }

                    // Ultra-compact micro-tag tucked right under the hardware cutout inside safe area
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 5, height: 5)
                            .opacity(pulse ? 0.35 : 1.0)

                        Text(microTitle)
                            .foregroundColor(.white.opacity(0.92))
                            .font(.system(size: 8.5, weight: .bold, design: .rounded).monospacedDigit())
                            .tracking(0.4)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(argb: 0xE605070C))
                    )
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.55), lineWidth: 0.8)
                    )
                    .padding(.top, topInset >= 51 ? 45 : max(topInset - 14, 28))
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var microTitle: String {
        if state.isTripRecording {
            let totalSec = Int(state.liveTripStats.elapsedMs / 1000)
            let m = totalSec / 60
            let s = totalSec % 60
            return String(format: "REC %.2f KM · %02d:%02d", state.liveTripStats.distanceKm, m, s)
        }
        if guardian.justReturnedFromBackground {
            return "CHẠY NGẦM BẢO VỆ ✓"
        }
        if state.connectionState == .connected {
            return state.reading.ecuConnected ? "ECU ONLINE · NGẦM BẬT" : "BLE ONLINE · NGẦM BẬT"
        }
        return "CHẠY NGẦM BẢO VỆ"
    }
}
