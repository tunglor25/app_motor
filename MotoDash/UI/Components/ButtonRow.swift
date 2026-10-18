import SwiftUI

struct ButtonRow: View {
    let lapRunning: Bool
    let isTripRecording: Bool
    let onSelClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onSetShortClick: () -> Void
    let onSetLongPress: () -> Void
    var onGearClick: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            DashButton(
                label: isTripRecording ? "● REC" : "TRIP",
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
            if let onGearClick {
                Spacer()
                Button(action: onGearClick) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("MENU")
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                            .tracking(1)
                    }
                    .foregroundColor(.dashCyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(argb: 0xFF111111))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.dashCyan.opacity(0.6), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

private struct DashButton: View {
    let label: String
    let highlighted: Bool
    let highlightColor: Color
    let longPressSeconds: Double?
    let onShortClick: () -> Void
    let onLongPress: () -> Void

    @State private var pressTask: Task<Void, Never>?
    @State private var longPressFired = false

    var body: some View {
        Text(label)
            .font(DashFont.shareTechMono(12))
            .tracking(2)
            .foregroundColor(highlighted ? highlightColor : .white)
            .modifier(ConditionalGlow(active: highlighted, color: highlightColor))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color(argb: 0xFF111111))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(highlighted ? highlightColor : Color(argb: 0xFF333333), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
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
