import Foundation
import SwiftUI

struct TripRecordingBar: View {
    let stats: LiveTripStats
    var onStop: (() -> Void)? = nil

    @State private var dotVisible = true

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.dashRed.opacity(dotVisible ? 1.0 : 0.2))
                    .frame(width: 8, height: 8)
                Text("ĐANG GHI TRIP")
                    .foregroundColor(.dashRed)
                    .font(DashFont.shareTechMono(11))
                    .fontWeight(.bold)
            }
            Spacer()
            Text(String(format: "%.2f km", stats.distanceKm))
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(11))
                .fontWeight(.bold)
            Text("·")
                .foregroundColor(.dashDim)
            Text(Self.formatElapsed(stats.elapsedMs))
                .foregroundColor(.dashCyan)
                .font(DashFont.shareTechMono(11))
                .fontWeight(.bold)
            Text("·")
                .foregroundColor(.dashDim)
            Text("MAX \(Int(stats.maxSpeedGpsKmh))km/h")
                .foregroundColor(.dashAmber)
                .font(DashFont.shareTechMono(10))
            if let onStop {
                Button(action: onStop) {
                    Text("⏹ DỪNG & LƯU")
                        .foregroundColor(.white)
                        .font(DashFont.shareTechMono(11))
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dashRed)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.dashRed.opacity(0.14))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashRed.opacity(0.6), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dotVisible = false
            }
        }
    }

    private static func formatElapsed(_ ms: Int64) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
