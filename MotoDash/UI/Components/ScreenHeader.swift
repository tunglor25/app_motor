import SwiftUI

/// Shared secondary-screen header (Settings/Diagnostics/Trip History/Trip Result).
struct ScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
                .font(DashFont.shareTechMono(18))
            Spacer()
            Button(action: onBack) {
                Text("\u{2190} Quay l\u{1EA1}i")
                    .foregroundColor(.dashCyan)
                    .font(DashFont.shareTechMono(13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dashCyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.dashCyan.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.bottom, 8)
    }
}
