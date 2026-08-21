import SwiftUI

// Matches race.html exactly: SEL and SET both short-click-toggle the lap timer;
// TRIP short-click starts GPS recording, a 1.5s hold while recording stops+saves it;
// SET's 1.2s hold resets the lap timer + trip odometer.
struct ButtonRow: View {
    let lapRunning: Bool
    let isTripRecording: Bool
    let onSelClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onSetShortClick: () -> Void
    let onSetLongPress: () -> Void

    var body: some View {
        HStack {
            DashButton(
                label: isTripRecording ? "\u{25CF} REC" : "TRIP",
                highlighted: isTripRecording,
                highlightColor: .dashRed,
                longPressSeconds: 1.5,
                onShortClick: onTripShortClick,
                onLongPress: onTripLongPress
            )
            Spacer()
            DashButton(
                label: lapRunning ? "STOP" : "SEL",
                highlighted: lapRunning,
                highlightColor: .dashCyan,
                longPressSeconds: nil,
                onShortClick: onSelClick,
                onLongPress: {}
            )
            Spacer()
            DashButton(
                label: "SET",
                highlighted: false,
                highlightColor: .dashCyan,
                longPressSeconds: 1.2,
                onShortClick: onSetShortClick,
                onLongPress: onSetLongPress
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

private struct DashButton: View {
    let label: String
    let highlighted: Bool
    let highlightColor: Color
    /// nil disables long-press handling entirely (matches the Kotlin source's SEL
    /// button, which passes Long.MAX_VALUE as its threshold).
    let longPressSeconds: Double?
    let onShortClick: () -> Void
    let onLongPress: () -> Void

    @State private var pressTask: Task<Void, Never>?
    @State private var longPressFired = false

    var body: some View {
        Text(label)
            .font(DashFont.shareTechMono(12))
            .tracking(3)
            .foregroundColor(highlighted ? highlightColor : .white)
            .modifier(ConditionalGlow(active: highlighted, color: highlightColor))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(argb: 0xFF111111))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(highlighted ? highlightColor : Color(argb: 0xFF333333), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard pressTask == nil else { return }
                        longPressFired = false
                        if let longPressSeconds {
                            pressTask = Task {
                                try? await Task.sleep(nanoseconds: UInt64(longPressSeconds * 1_000_000_000))
                                if !Task.isCancelled {
                                    longPressFired = true
                                    onLongPress()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        pressTask?.cancel()
                        pressTask = nil
                        if !longPressFired {
                            onShortClick()
                        }
                    }
            )
    }
}

private struct ConditionalGlow: ViewModifier {
    let active: Bool
    let color: Color

    func body(content: Content) -> some View {
        if active {
            content.textGlow(color, radius: 8)
        } else {
            content
        }
    }
}
