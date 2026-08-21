import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0x05 / 255, green: 0x06 / 255, blue: 0x08 / 255)
                .ignoresSafeArea()
            Text("MotoDash")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentView()
}
