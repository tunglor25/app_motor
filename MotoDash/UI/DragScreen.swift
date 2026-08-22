import SwiftUI

/// Do gia toc 0-40/0-60/100m tu du lieu Speed/TPS/RPM da co san qua BLE --
/// khong can GPS. Xem DragRecorder.swift cho state machine chi tiet. Mirrors
/// the Kotlin source's ui/DragScreen.kt.
struct DragScreen: View {
    @ObservedObject var recorder: DragRecorder
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    RacingStripe()
                    ScreenHeader(title: "\u{0110}O GIA T\u{1ED0}C", onBack: onBack)
                        .padding(.leading, 12)
                }

                VStack(alignment: .leading) {
                    switch recorder.state {
                    case .idle:
                        IdleContent(onArm: recorder.arm)
                    case .staged:
                        StagedContent(onCancel: recorder.cancel)
                    case .running:
                        RunningContent(
                            elapsedMs: recorder.elapsedMs,
                            to40Ms: recorder.to40Ms,
                            to60Ms: recorder.to60Ms,
                            to100mMs: recorder.to100mMs
                        )
                    case .finished:
                        FinishedContent(
                            run: recorder.lastRun,
                            best: recorder.bestRun,
                            isNewRecord: recorder.isNewRecord,
                            onRetry: recorder.arm,
                            onCancel: recorder.cancel
                        )
                    }
                }
                .padding(.top, 20)
            }
            .padding(16)
        }
        .dashboardBackground()
    }
}

private struct IdleContent: View {
    let onArm: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("\u{0110}o th\u{1EDD}i gian t\u{0103}ng t\u{1ED1}c 0-40, 0-60 km/h v\u{00E0} 100m \u{0111}\u{1EA7}u ti\u{00EA}n b\u{1EB1}ng d\u{1EEF} li\u{1EC7}u t\u{1ED1}c \u{0111}\u{1ED9}/ga th\u{1EAD}t t\u{1EEB} ECU. Kh\u{00F4}ng c\u{1EA7}n GPS.")
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(13))
                .padding(.bottom, 20)
            BigButton(text: "B\u{1EAF}T \u{0110}\u{1EA6}U", color: .dashCyan, onClick: onArm)
        }
    }
}

private struct StagedContent: View {
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text("\u{1F3C1} S\u{1EB4}N S\u{00C0}NG\nD\u{1EEB}ng h\u{1EB3}n xe, v\u{1EB7}n ga h\u{1EBF}t c\u{1EE1} \u{0111}\u{1EC3} b\u{1EAF}t \u{0111}\u{1EA7}u b\u{1EA5}m gi\u{1EDD}")
                .foregroundColor(.dashAmber)
                .font(DashFont.shareTechMono(16))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.dashAmber.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dashAmber.opacity(0.4), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer().frame(height: 16)
            BigButton(text: "H\u{1EE6}Y", color: .dashTextSecondary, onClick: onCancel)
        }
    }
}

private struct RunningContent: View {
    let elapsedMs: Int64
    let to40Ms: Int64?
    let to60Ms: Int64?
    let to100mMs: Int64?

    var body: some View {
        VStack(alignment: .leading) {
            Text(String(format: "%.2fs", Double(elapsedMs) / 1000.0))
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(56))
                .fontWeight(.bold)
                .textGlow(.dashCyan, radius: 20)
            Spacer().frame(height: 20)
            SplitRow(label: "0-40 km/h", timeMs: to40Ms)
            SplitRow(label: "0-60 km/h", timeMs: to60Ms)
            SplitRow(label: "100m \u{0111}\u{1EA7}u", timeMs: to100mMs)
        }
    }
}

private struct FinishedContent: View {
    let run: DragRun?
    let best: DragRun?
    let isNewRecord: Bool
    let onRetry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        if let run {
            VStack(alignment: .leading) {
                if isNewRecord {
                    Text("\u{1F3C6} K\u{1EF2} L\u{1EE4}C M\u{1EDA}I!")
                        .foregroundColor(.dashGreen)
                        .font(DashFont.shareTechMono(20))
                        .fontWeight(.bold)
                        .textGlow(.dashGreen, radius: 14)
                        .padding(.bottom, 12)
                }
                SplitRow(label: "0-40 km/h", timeMs: run.to40Ms, best: best?.to40Ms)
                SplitRow(label: "0-60 km/h", timeMs: run.to60Ms, best: best?.to60Ms)
                SplitRow(label: "100m \u{0111}\u{1EA7}u", timeMs: run.to100mMs, best: best?.to100mMs)

                if run.samples.count > 1 {
                    Spacer().frame(height: 16)
                    Text("T\u{1ED0}C \u{0110}\u{1ED8} / V\u{00D2}NG TUA THEO TH\u{1EDC}I GIAN")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                        .tracking(1)
                    Spacer().frame(height: 8)
                    DragChart(samples: run.samples)
                }

                Spacer().frame(height: 20)
                HStack {
                    BigButton(text: "TH\u{1EEC} L\u{1EA0}I", color: .dashCyan, onClick: onRetry)
                    Spacer().frame(width: 12)
                    BigButton(text: "THO\u{00C1}T", color: .dashTextSecondary, onClick: onCancel)
                }
            }
        }
    }
}

private struct SplitRow: View {
    let label: String
    let timeMs: Int64?
    var best: Int64?

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(13))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(timeMs.map { String(format: "%.2fs", Double($0) / 1000.0) } ?? "--")
                .foregroundColor(timeMs != nil ? .white : .dashTextSecondary)
                .font(DashFont.shareTechMono(22))
                .fontWeight(.bold)
            if let best, timeMs != nil {
                Text(String(format: "  (k\u{1EF7} l\u{1EE5}c: %.2fs)", Double(best) / 1000.0))
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
            }
        }
        .padding(16)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 6)
    }
}

private struct BigButton: View {
    let text: String
    let color: Color
    let onClick: () -> Void

    var body: some View {
        Text(text)
            .foregroundColor(color)
            .font(DashFont.shareTechMono(15))
            .fontWeight(.bold)
            .tracking(2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(argb: 0xFF111111))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .onTapGesture(perform: onClick)
    }
}

/// Bieu do duong cong Speed (cyan) + RPM (amber, ty le rieng) theo thoi gian,
/// tu ve bang Canvas -- khong can thu vien bieu do rieng.
private struct DragChart: View {
    let samples: [DragSample]

    var body: some View {
        let maxTime = Double(max(samples.last?.timeMs ?? 1, 1))
        let maxSpeed = Double(max(samples.map(\.speedKmh).max() ?? 1, 1))
        let maxRpm = Double(max(samples.map(\.rpm).max() ?? 1, 1))

        Canvas { context, size in
            func points(_ valueOf: (DragSample) -> Double, maxValue: Double) -> [CGPoint] {
                samples.map { s in
                    CGPoint(
                        x: (Double(s.timeMs) / maxTime) * size.width,
                        y: size.height - (valueOf(s) / maxValue) * size.height
                    )
                }
            }

            func drawSeries(_ pts: [CGPoint], color: Color) {
                guard pts.count > 1 else { return }
                var path = Path()
                path.addLines(pts)
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            drawSeries(points({ Double($0.rpm) }, maxValue: maxRpm), color: Color.dashAmber.opacity(0.6))
            drawSeries(points({ Double($0.speedKmh) }, maxValue: maxSpeed), color: .dashCyan)
        }
        .frame(height: 160)
        .padding(12)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
