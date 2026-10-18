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
            VStack(spacing: 4) {
                HStack {
                    Image("logo_\(state.settings.brandLogo)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Text("DAILY // COMMUTER")
                        .foregroundColor(.dashCyan)
                        .font(DashFont.shareTechMono(12))
                        .tracking(2)
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(Self.clockString(from: context.date))
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(15))
                    }
                    Button(action: onGearClick) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("CÀI ĐẶT")
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.dashCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.dashCyan.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan.opacity(0.6), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                if state.isTripRecording {
                    TripRecordingBar(stats: state.liveTripStats)
                }

                ZStack {
                    SemicircularArcGauge(ratio: rpmRatio)
                        .frame(maxWidth: 280, maxHeight: 170)
                    VStack(spacing: 2) {
                        Text(UnitConversions.speedText(state.reading.speed, unitSpeed: state.settings.unitSpeed))
                            .foregroundColor(.white)
                            .font(DashFont.rajdhani(54, weight: .semibold))
                            .minimumScaleFactor(0.6)
                        Text(UnitConversions.speedUnitLabel(state.settings.unitSpeed))
                            .foregroundColor(.dashDim)
                            .font(DashFont.shareTechMono(12))
                        Text("\(state.reading.rpm ?? 0) RPM")
                            .foregroundColor(.dashCyan)
                            .font(DashFont.shareTechMono(12))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    LcdCell(label: "TRIP", value: state.isTripRecording ? "● REC" : "▶ BẮT ĐẦU")
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
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .background(
            RadialGradient(colors: [Color(argb: 0xFF061924), Color(argb: 0xFF02080D)], center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
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
        VStack(spacing: 2) {
            Text(value).foregroundColor(.white).font(DashFont.shareTechMono(13))
            Text(label).foregroundColor(.dashDim).font(DashFont.shareTechMono(9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }
}
