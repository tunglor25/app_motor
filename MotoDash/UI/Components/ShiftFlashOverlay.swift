import SwiftUI

// Only animates while rpm >= threshold -- no infinite animation running in the
// background otherwise (battery), mirroring race.html's `.active` gating.
// threshold comes from settings.rpmWarnVal * 1000 (or disabled -> Int.max).
struct ShiftFlashOverlay: View {
    let rpm: Int?
    let threshold: Int

    @State private var flashOn = false

    var body: some View {
        Group {
            if (rpm ?? 0) >= threshold {
                Color.dashRed
                    .opacity(flashOn ? 0.4 : 0.0)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                            flashOn = true
                        }
                    }
                    .onDisappear { flashOn = false }
                    .allowsHitTesting(false)
            }
        }
    }
}
