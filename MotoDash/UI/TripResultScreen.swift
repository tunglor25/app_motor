import Foundation
import SwiftUI

struct TripResultScreen: View {
    let tripId: String
    let tripRepository: TripRepository
    let onBack: () -> Void

    @State private var trip: TripRecord?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    RacingStripe()
                    ScreenHeader(title: "K\u{1EBE}T QU\u{1EA2} H\u{00C0}NH TR\u{00CC}NH", onBack: onBack)
                        .padding(.leading, 12)
                }

                if loaded, trip == nil {
                    Text("Kh\u{00F4}ng t\u{00EC}m th\u{1EA5}y h\u{00E0}nh tr\u{00EC}nh n\u{00E0}y.")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(13))
                        .padding(.top, 24)
                }

                if let t = trip {
                    VStack {
                        if t.routeCoords.count >= 2 {
                            TripRouteMap(points: t.routeCoords)
                                .frame(height: 220)
                                .padding(.bottom, 12)
                        }
                        HStack(spacing: 10) {
                            StatCard(label: "QU\u{00C3}NG \u{0110}\u{01AF}\u{1EDC}NG", value: String(format: "%.2f km", t.totalDistance))
                            StatCard(label: "TH\u{1EDC}I GIAN", value: Self.formatDuration(t.duration))
                        }
                        HStack(spacing: 10) {
                            StatCard(label: "T\u{1ED0}C \u{0110}\u{1ED8} T\u{1ED0}I \u{0110}A", value: "\(Int(t.maxSpeedECU)) km/h", sub: "GPS \(Int(t.maxSpeedGPS))")
                            StatCard(label: "T\u{1ED0}C \u{0110}\u{1ED8} TB", value: "\(Int(t.avgSpeedECU)) km/h", sub: "GPS \(Int(t.avgSpeedGPS))")
                        }
                        HStack(spacing: 10) {
                            StatCard(label: "RPM MAX / TB", value: "\(t.maxRPM)", sub: "TB \(Int(t.avgRPM))")
                            StatCard(label: "NHI\u{1EC6}T \u{0110}\u{1ED8} MAX", value: "\(t.maxECT)\u{00B0}C")
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .padding(16)
        }
        .dashboardBackground()
        .task(id: tripId) {
            trip = await tripRepository.getTripById(tripId)
            loaded = true
        }
    }

    private static func formatDuration(_ ms: Int64) -> String {
        let totalSeconds = ms / 1000
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    var sub: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .foregroundColor(.dashTextSecondary)
                .font(DashFont.shareTechMono(11))
                .tracking(1)
            Text(value)
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(24))
                .fontWeight(.bold)
                .textGlow(.dashCyan, radius: 8)
            if let sub {
                Text(sub)
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dashCardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(4)
    }
}
