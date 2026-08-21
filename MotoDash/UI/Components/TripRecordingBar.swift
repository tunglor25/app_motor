import Foundation
import SwiftUI

struct TripRecordingBar: View {
    let stats: LiveTripStats

    @State private var dotVisible = true

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.dashRed.opacity(dotVisible ? 1.0 : 0.2))
                    .frame(width: 8, height: 8)
                Text("REC")
                    .foregroundColor(.dashRed)
                    .font(DashFont.shareTechMono(11))
            }
            Spacer()
            Text(String(format: "DIST %.2fkm", stats.distanceKm))
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(11))
            Spacer()
            Text("TIME \(Self.formatElapsed(stats.elapsedMs))")
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(11))
            Spacer()
            Text("MAX \(Int(stats.maxSpeedGpsKmh))km/h")
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(11))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
