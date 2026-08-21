import SwiftUI

// Native port of race.html's speed-limit sign: circular badge, pulses red when
// the current speed exceeds the fetched limit (real TomTom/OSM lookup via
// SpeedLimitTracker). VN road coverage for posted limits is genuinely sparse in
// both free sources, so rather than sit there showing a permanent "--" (which
// reads as broken), the badge simply doesn't render until real data exists.
struct SpeedLimitBadge: View {
    let speedLimitKmh: Int
    let currentSpeed: Int?
    let enabled: Bool

    @State private var pulse = false

    var body: some View {
        Group {
            if enabled, speedLimitKmh > 0 {
                let overspeed = (currentSpeed ?? 0) > speedLimitKmh
                ZStack {
                    Circle().fill(Color.black)
                    Circle().stroke(overspeed ? Color.dashRed : Color.white, lineWidth: 3)
                    Text("\(speedLimitKmh)")
                        .font(DashFont.orbitron(18))
                        .foregroundColor(overspeed ? .dashRed : .white)
                }
                .frame(width: 52, height: 52)
                .scaleEffect(overspeed && pulse ? 1.15 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
                .onDisappear { pulse = false }
            }
        }
    }
}
