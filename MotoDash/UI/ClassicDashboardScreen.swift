import Foundation
import SwiftUI

private let classicMaxSpeed: Double = 140
private let classicMaxRpm: Double = 14000
private let classicNeedleColor = Color(argb: 0xFFFF8A1E)

// Vintage/brass palette (#c9b98c body / #0a0a0a bg) from the Kotlin source is
// simplified to the shared dark palette here to avoid a second parallel theme
// system -- needle color and twin-dial layout are kept faithful.
struct ClassicDashboardScreen: View {
    let state: DashboardUiState
    @ObservedObject var mediaSessionReader: MediaSessionReader
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onTripSaved: (String) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text(state.isTripRecording ? "\u{25CF} REC" : "TRIP")
                        .foregroundColor(state.isTripRecording ? Color(argb: 0xFFC23B2C) : .dashDim)
                        .font(DashFont.shareTechMono(13))
                        .onTapGesture {
                            if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                        }
                    Spacer()
                    Button(action: onGearClick) {
                        Text("\u{2699}").foregroundColor(.dashDim).font(.system(size: 18))
                    }
                }
                .padding(12)

                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }

                HStack(spacing: 12) {
                    AnalogNeedleDial(
                        ratio: Double(state.reading.speed ?? 0) / classicMaxSpeed,
                        valueText: UnitConversions.speedText(state.reading.speed, unitSpeed: state.settings.unitSpeed),
                        subText: UnitConversions.speedUnitLabel(state.settings.unitSpeed),
                        label: "MOTO \u{00B7} CLASSIC",
                        needleColor: classicNeedleColor
                    )
                    AnalogNeedleDial(
                        ratio: Double(state.reading.rpm ?? 0) / classicMaxRpm,
                        valueText: String(format: "%.1f", Double(state.reading.rpm ?? 0) / 1000),
                        subText: "x1000",
                        label: "TACHOMETER",
                        needleColor: classicNeedleColor
                    )
                }
                .padding(16)
                .frame(maxHeight: .infinity)

                HStack {
                    Spacer()
                    VitalText(label: "BATT", value: state.reading.battery.map { String(format: "%.1fV", $0) } ?? "--")
                    Spacer()
                    VitalText(label: "TPS", value: state.reading.tps.map { "\($0)%" } ?? "--")
                    Spacer()
                    VitalText(
                        label: "TEMP",
                        value: state.reading.ect.map { UnitConversions.tempText($0, unitTemp: state.settings.unitTemp) + UnitConversions.tempUnitLabel(state.settings.unitTemp) } ?? "--"
                    )
                    Spacer()
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
                SpeedLimitBadge(speedLimitKmh: state.speedLimitKmh, currentSpeed: state.reading.speed, enabled: state.settings.speedWarnEnabled)
                    .padding(.top, 8)
                Spacer()
            }

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(Color(argb: 0xFF0A0A0A))
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct VitalText: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value).foregroundColor(Color(argb: 0xFFC9B98C)).font(DashFont.shareTechMono(16))
            Text(label).foregroundColor(.dashDim).font(DashFont.shareTechMono(10))
        }
    }
}
