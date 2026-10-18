import Foundation
import SwiftUI

private let classicMaxSpeed: Double = 140
private let classicMaxRpm: Double = 14000
private let classicNeedleColor = Color(argb: 0xFFFF8A1E)

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
            VStack(spacing: 4) {
                HStack {
                    Image("logo_\(state.settings.brandLogo)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Button(action: {
                        if !state.isTripRecording { onTripShortClick() } else { onTripLongPress() }
                    }) {
                        Text(state.isTripRecording ? "● REC TRIP" : "▶ TRIP")
                            .foregroundColor(state.isTripRecording ? Color(argb: 0xFFC23B2C) : Color(argb: 0xFFC9B98C))
                            .font(DashFont.shareTechMono(12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onGearClick) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("CÀI ĐẶT")
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(Color(argb: 0xFFC9B98C))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(argb: 0xFFC9B98C).opacity(0.5), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }

                HStack(spacing: 16) {
                    AnalogNeedleDial(
                        ratio: Double(state.reading.speed ?? 0) / classicMaxSpeed,
                        valueText: UnitConversions.speedText(state.reading.speed, unitSpeed: state.settings.unitSpeed),
                        subText: UnitConversions.speedUnitLabel(state.settings.unitSpeed),
                        label: "MOTO · CLASSIC",
                        needleColor: classicNeedleColor
                    )
                    .frame(maxHeight: 190)

                    AnalogNeedleDial(
                        ratio: Double(state.reading.rpm ?? 0) / classicMaxRpm,
                        valueText: String(format: "%.1f", Double(state.reading.rpm ?? 0) / 1000),
                        subText: "x1000",
                        label: "TACHOMETER",
                        needleColor: classicNeedleColor
                    )
                    .frame(maxHeight: 190)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                .padding(.bottom, 6)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(Color(argb: 0xFF0A0A0A).ignoresSafeArea())
        .onChange(of: state.savedTripId) { newValue in
            if let id = newValue { onTripSaved(id) }
        }
    }
}

private struct VitalText: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).foregroundColor(Color(argb: 0xFFC9B98C)).font(DashFont.shareTechMono(15))
            Text(label).foregroundColor(.dashDim).font(DashFont.shareTechMono(9))
        }
    }
}
