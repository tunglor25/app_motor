import Foundation
import SwiftUI

private let dailyMaxRpm: Double = 12000

struct DailyDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    private var rpmRatio: Double {
        Double(state.reading.rpm ?? 0) / dailyMaxRpm
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(Self.clockString(from: context.date))
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(16))
                    }
                    Button(action: onGearClick) {
                        Text("\u{2699}").foregroundColor(.dashDim).font(.system(size: 18))
                    }
                    .padding(.leading, 12)
                }
                .padding(12)

                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }

                ZStack {
                    SemicircularArcGauge(ratio: rpmRatio)
                    VStack(spacing: 2) {
                        Text(UnitConversions.speedText(state.reading.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(.white)
                            .font(DashFont.rajdhani(56, weight: .semibold))
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed))
                            .foregroundColor(.dashDim)
                            .font(DashFont.shareTechMono(12))
                        Text("\(state.reading.rpm ?? 0) RPM")
                            .foregroundColor(.dashDim)
                            .font(DashFont.shareTechMono(12))
                            .padding(.top, 4)
                    }
                }
                .padding(24)
                .frame(maxHeight: .infinity)

                HStack(spacing: 8) {
                    LcdCell(label: "TRIP", value: state.isTripRecording ? "\u{25CF} REC" : "\u{25B6}")
                        .onTapGesture {
                            if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                        }
                    LcdCell(label: "TPS", value: state.reading.tps.map { "\($0)%" } ?? "--")
                    LcdCell(label: "BATT", value: state.reading.battery.map { String(format: "%.1fV", $0) } ?? "--")
                    LcdCell(
                        label: "TEMP",
                        value: state.reading.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            VStack {
                Spacer()
                HStack {
                    MusicWidget(reader: mediaSessionReader)
                    Spacer()
                }
            }
            .padding(16)

            VStack {
                HStack {
                    Spacer()
                    SpeedLimitBadge(speedLimitKmh: state.speedLimitKmh, currentSpeed: state.reading.speed, enabled: state.settings.speedWarnEnabled)
                }
                Spacer()
            }
            .padding(.top, 60)
            .padding(.trailing, 16)

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF061924), Color(argb: 0xFF02080D)], center: .center, startRadius: 0, endRadius: 500)
        )
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }

    private static func clockString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct LcdCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value).foregroundColor(.white).font(DashFont.shareTechMono(14))
            Text(label).foregroundColor(.dashDim).font(DashFont.shareTechMono(9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
