import SwiftUI

struct ScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(17))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Button(action: onBack) {
                Text("← Quay lại")
                    .foregroundColor(.dashCyan)
                    .font(DashFont.shareTechMono(13))
                    .fontWeight(.bold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.dashCyan.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dashCyan.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}
