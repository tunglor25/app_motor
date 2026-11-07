import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

struct MotoDashWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MotoDashSharedSnapshot
}

struct MotoDashTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MotoDashWidgetEntry {
        MotoDashWidgetEntry(
            date: Date(),
            snapshot: MotoDashSharedSnapshot(
                speedKmh: 48,
                rpm: 5200,
                ectCelsius: 84,
                batteryVolts: 13.8,
                isBleConnected: true,
                isEcuOnline: true,
                isTripRecording: true,
                tripDistanceKm: 12.4,
                tripElapsedSec: 940
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MotoDashWidgetEntry) -> Void) {
        let snap = MotoDashSharedSnapshot.load()
        completion(MotoDashWidgetEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MotoDashWidgetEntry>) -> Void) {
        let snap = MotoDashSharedSnapshot.load()
        let entry = MotoDashWidgetEntry(date: Date(), snapshot: snap)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct MotoDashWidgetEntryView: View {
    var entry: MotoDashTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    private let neonCyan = Color(red: 0.0, green: 0.71, blue: 0.85)
    private let neonRed = Color(red: 1.0, green: 0.15, blue: 0.23)
    private let neonGreen = Color(red: 0.13, green: 0.77, blue: 0.37)

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: entry.snapshot.isTripRecording ? "record.circle.fill" : "shield.lefthalf.filled")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(entry.snapshot.speedKmh)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text("KM/H")
                        .font(.system(size: 7, weight: .bold))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: entry.snapshot.isTripRecording ? "record.circle.fill" : "bolt.shield.fill")
                    Text("AIR BLADE 125 · NGẦM BẬT")
                        .font(.system(size: 10, weight: .heavy))
                }
                Text("SPD \(entry.snapshot.speedKmh) km/h · RPM \(entry.snapshot.rpm)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text(String(format: "BAT %.1fV · ECT %d°C · TRIP %.1fkm", entry.snapshot.batteryVolts, entry.snapshot.ectCelsius, entry.snapshot.tripDistanceKm))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        case .systemMedium:
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.06, blue: 0.10), Color(red: 0.02, green: 0.03, blue: 0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(entry.snapshot.isTripRecording ? neonRed : neonGreen)
                                .frame(width: 8, height: 8)
                            Text("AIR BLADE 125 // 2025")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(neonRed)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(entry.snapshot.speedKmh)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("km/h")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                        Text(entry.snapshot.isTripRecording ? "🔴 ĐANG GHI HÀNH TRÌNH" : "🛡️ CHẠY NGẦM BẢO VỆ: BẬT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(entry.snapshot.isTripRecording ? neonRed : neonGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        WidgetMetricRow(label: "RPM", value: "\(entry.snapshot.rpm)", color: neonCyan)
                        WidgetMetricRow(label: "ECT", value: "\(entry.snapshot.ectCelsius)°C", color: neonGreen)
                        WidgetMetricRow(label: "BATT", value: String(format: "%.1fV", entry.snapshot.batteryVolts), color: .yellow)
                        WidgetMetricRow(label: "TRIP", value: String(format: "%.2f km", entry.snapshot.tripDistanceKm), color: neonRed)
                    }
                }
                .padding(14)
            }
        default:
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.07, blue: 0.11), Color(red: 0.02, green: 0.03, blue: 0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(entry.snapshot.isTripRecording ? neonRed : neonGreen)
                            .frame(width: 7, height: 7)
                        Text("AB125 PRO")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(neonRed)
                    }
                    Spacer()
                    Text("\(entry.snapshot.speedKmh)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("km/h · \(entry.snapshot.rpm) RPM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Spacer()
                    Text(String(format: "TRIP %.1fkm · %.1fV", entry.snapshot.tripDistanceKm, entry.snapshot.batteryVolts))
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(neonGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
    }
}

private struct WidgetMetricRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct MotoDashTelemetryWidget: Widget {
    let kind: String = "MotoDashTelemetryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotoDashTimelineProvider()) { entry in
            MotoDashWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MotoDash Air Blade 125")
        .description("Hiển thị Tốc độ, Tua máy, Điện áp bình, Hành trình & Trạng thái chạy ngầm bảo vệ xe.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct MotoDashLiveActivityWidget: Widget {
    private let neonCyan = Color(red: 0.0, green: 0.71, blue: 0.85)
    private let neonRed = Color(red: 1.0, green: 0.15, blue: 0.23)
    private let neonGreen = Color(red: 0.13, green: 0.77, blue: 0.37)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MotoDashActivityAttributes.self) { context in
            // Lock Screen / Banner Live Activity UI
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(context.state.isTripRecording ? neonRed : neonGreen)
                            .frame(width: 8, height: 8)
                        Text(context.state.isTripRecording ? "MOTODASH · ĐANG GHI HÀNH TRÌNH" : "MOTODASH · ĐANG CHẠY NGẦM BẢO VỆ XE")
                            .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(context.state.isTripRecording ? neonRed : neonGreen)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(context.state.speedKmh) km/h")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("· \(context.state.rpm) RPM")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    Text(String(format: "TRIP: %.2f km · ECT: %d°C · BATT: %.1fV · 5 Lớp Khóa: ON", context.state.tripDistanceKm, context.state.ectCelsius, context.state.batteryVolts))
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(14)
            .activityBackgroundTint(Color(red: 0.04, green: 0.05, blue: 0.08))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: context.state.isTripRecording ? "record.circle.fill" : "bolt.shield.fill")
                                .foregroundColor(context.state.isTripRecording ? neonRed : neonGreen)
                            Text("AB125 PRO")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Text("\(context.state.speedKmh) km/h")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(neonCyan)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.isTripRecording ? "🔴 REC TRIP" : "🛡️ NGẦM BẬT")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(context.state.isTripRecording ? neonRed : neonGreen)
                        Text(String(format: "%.2f km", context.state.tripDistanceKm))
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("RPM \(context.state.rpm)")
                        Spacer()
                        Text("ECT \(context.state.ectCelsius)°C")
                        Spacer()
                        Text(String(format: "BAT %.1fV", context.state.batteryVolts))
                        Spacer()
                        Text("5 LỚP KHÓA ✓")
                            .foregroundColor(neonGreen)
                    }
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(context.state.isTripRecording ? neonRed : neonGreen)
                        .frame(width: 7, height: 7)
                    Text(context.state.isTripRecording ? "REC" : "AB125")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(context.state.isTripRecording ? neonRed : neonGreen)
                }
            } compactTrailing: {
                Text(context.state.isTripRecording ? String(format: "%.1fkm", context.state.tripDistanceKm) : "\(context.state.speedKmh)km/h")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
            } minimal: {
                Image(systemName: context.state.isTripRecording ? "record.circle.fill" : "bolt.shield.fill")
                    .foregroundColor(context.state.isTripRecording ? neonRed : neonGreen)
            }
        }
    }
}
#endif

@main
struct MotoDashWidgetBundle: WidgetBundle {
    var body: some Widget {
        MotoDashTelemetryWidget()
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            MotoDashLiveActivityWidget()
        }
        #endif
    }
}
