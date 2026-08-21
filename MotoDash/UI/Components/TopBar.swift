import Foundation
import SwiftUI

// Brand logo is omitted -- no logo asset system built. Matches race.html:
// dim/small labels + cyan/glowing values split, and the clock is cyan+glow+
// letter-spacing, not plain white.
struct TopBar: View {
    let lapText: String
    let tripKm: Double
    let onGearClick: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                InfoLine(label: "LAP", value: lapText)
                InfoLine(label: "TRIP", value: String(format: "%.1f km", tripKm))
            }
            Spacer()
            HStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(Self.clockString(from: context.date))
                        .foregroundColor(.dashCyan)
                        .font(DashFont.shareTechMono(16))
                        .tracking(2)
                        .textGlow(.dashCyan, radius: 10)
                }
                Button(action: onGearClick) {
                    Text("\u{2699}")
                        .foregroundColor(.dashDim)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private static func clockString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct InfoLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text("\(label) ")
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(11))
                .tracking(1)
            Text(value)
                .foregroundColor(.dashCyan)
                .font(DashFont.shareTechMono(12))
                .textGlow(.dashCyan, radius: 6)
        }
    }
}
