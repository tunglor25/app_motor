import Foundation
import SwiftUI

struct TripHistoryScreen: View {
    let tripRepository: TripRepository
    var isTripRecording: Bool = false
    var liveStats: LiveTripStats = LiveTripStats()
    var onStartTrip: () -> Void = {}
    var onStopTrip: () -> Void = {}
    var onCancelTrip: () -> Void = {}
    let onOpenTrip: (String) -> Void
    let onBack: () -> Void

    @State private var trips: [TripRecord] = []
    @State private var deleteConfirmId: String?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                RacingStripe()
                ScreenHeader(title: "L\u{1ECA}CH S\u{1EEC} H\u{00C0}NH TR\u{00CC}NH", onBack: onBack)
                    .padding(.leading, 12)
            }

            // Live Trip Control Banner
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(isTripRecording ? Color.dashRed : Color.dashCyan)
                        .frame(width: 10, height: 10)
                    Text(isTripRecording ? "ĐANG GHI HÀNH TRÌNH TRỰC TIẾP" : "GHI HÀNH TRÌNH MỚI (GPS + ECU)")
                        .foregroundColor(isTripRecording ? .dashRed : .dashCyan)
                        .font(DashFont.shareTechMono(12))
                        .fontWeight(.bold)
                    Spacer()
                    if isTripRecording {
                        Text(String(format: "%.2f km · %@", liveStats.distanceKm, Self.formatElapsed(liveStats.elapsedMs)))
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                    }
                }
                HStack(spacing: 10) {
                    if isTripRecording {
                        Button(action: {
                            onStopTrip()
                            Task {
                                try? await Task.sleep(nanoseconds: 350_000_000)
                                await reload()
                            }
                        }) {
                            Text("⏹ DỪNG & LƯU HÀNH TRÌNH")
                                .foregroundColor(.white)
                                .font(DashFont.shareTechMono(13))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.dashRed)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: onCancelTrip) {
                            Text("✕ HỦY")
                                .foregroundColor(.dashTextSecondary)
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCardBorder, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: onStartTrip) {
                            Text("▶ BẮT ĐẦU HÀNH TRÌNH MỚI")
                                .foregroundColor(.dashCyan)
                                .font(DashFont.shareTechMono(13))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.dashCyan.opacity(0.14))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(isTripRecording ? Color.dashRed.opacity(0.12) : Color.dashCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isTripRecording ? Color.dashRed.opacity(0.6) : Color.dashCardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 10)

            if trips.isEmpty {
                VStack {
                    ZStack {
                        Circle().fill(Color.dashCardBackground)
                        Circle().stroke(Color.dashCardBorder, lineWidth: 1)
                        Image(systemName: "bicycle")
                            .foregroundColor(.dashTextSecondary)
                    }
                    .frame(width: 64, height: 64)

                    Text("Ch\u{01B0}a c\u{00F3} h\u{00E0}nh tr\u{00EC}nh n\u{00E0}o \u{0111}\u{01B0}\u{1EE3}c l\u{01B0}u.")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(13))
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }

            ScrollView {
                LazyVStack {
                    ForEach(trips) { trip in
                        TripRow(
                            trip: trip,
                            confirmingDelete: deleteConfirmId == trip.id,
                            onClick: { onOpenTrip(trip.id) },
                            onLongPress: { deleteConfirmId = trip.id },
                            onConfirmDelete: {
                                Task {
                                    await tripRepository.deleteTrip(trip.id)
                                    deleteConfirmId = nil
                                    await reload()
                                }
                            }
                        )
                    }
                }
            }
            .padding(.top, 16)
        }
        .padding(16)
        .dashboardBackground()
        .task { await reload() }
    }

    private func reload() async {
        trips = await tripRepository.getAllTrips()
    }

    private static func formatElapsed(_ ms: Int64) -> String {
        let totalSeconds = ms / 1000
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct TripRow: View {
    let trip: TripRecord
    let confirmingDelete: Bool
    let onClick: () -> Void
    let onLongPress: () -> Void
    let onConfirmDelete: () -> Void

    var body: some View {
        HStack {
            HStack {
                ZStack {
                    Circle().fill(Color.white.opacity(0.05))
                    Image(systemName: "location.north.line.fill")
                        .foregroundColor(.dashCyan)
                        .font(.system(size: 14))
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.formatDate(trip.startTime))
                        .foregroundColor(.white)
                        .font(DashFont.shareTechMono(13))
                    Text(String(format: "%.2f km \u{00B7} %@", trip.totalDistance, Self.formatDuration(trip.duration)))
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                }
                .padding(.leading, 12)
            }
            Spacer()
            Text(confirmingDelete ? "Ch\u{1EA1}m \u{0111}\u{1EC3} x\u{00F3}a" : "\(Int(trip.maxSpeedECU)) km/h max")
                .foregroundColor(confirmingDelete ? .dashRed : .dashTextSecondary)
                .font(DashFont.shareTechMono(12))
        }
        .padding(16)
        .background(confirmingDelete ? Color.dashRed.opacity(0.15) : Color.dashCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(confirmingDelete ? Color.dashRed.opacity(0.5) : Color.dashCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { confirmingDelete ? onConfirmDelete() : onClick() }
        .onLongPressGesture { onLongPress() }
    }

    private static func formatDate(_ epochMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(epochMs) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }

    private static func formatDuration(_ ms: Int64) -> String {
        let totalSeconds = ms / 1000
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
