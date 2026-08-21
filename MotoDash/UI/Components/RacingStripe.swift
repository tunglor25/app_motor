import SwiftUI

/// Small motorsport-livery mark -- two skewed bars, echoing the tachometer's angular character.
struct RacingStripe: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.dashCyan)
                .frame(width: 6, height: 22)
                .rotationEffect(.degrees(-18))
            Rectangle()
                .fill(Color.dashRed)
                .frame(width: 6, height: 22)
                .rotationEffect(.degrees(-18))
        }
    }
}
