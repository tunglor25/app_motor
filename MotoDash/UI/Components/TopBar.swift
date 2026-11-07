import Foundation
import SwiftUI

struct TopBar: View {
    let lapText: String
    let tripKm: Double
    var brandLogo: String = "honda"
    let onGearClick: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image("logo_\(brandLogo)")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                Text(brandLogo.uppercased())
                    .foregroundColor(.dashCyan)
                    .font(DashFont.shareTechMono(12))
                    .fontWeight(.bold)
                    .tracking(1)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .textGlow(.dashCyan, radius: 6)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                InfoLine(label: "LAP", value: lapText)
                InfoLine(label: "TRIP", value: String(format: "%.1fkm", tripKm))
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 4)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.clockString(from: context.date))
                    .foregroundColor(.dashCyan)
                    .font(DashFont.shareTechMono(14))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: true, vertical: false)
                    .textGlow(.dashCyan, radius: 8)
            }

            Button(action: onGearClick) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("CÀI ĐẶT")
                        .font(DashFont.shareTechMono(11.5))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(.dashCyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.dashCyan.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.dashCyan.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private static func clockString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct InfoLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(.dashDim)
                .font(DashFont.shareTechMono(11))
                .tracking(1)
            Text(value)
                .foregroundColor(.dashCyan)
                .font(DashFont.shareTechMono(13))
                .fontWeight(.bold)
                .textGlow(.dashCyan, radius: 6)
        }
    }
}
