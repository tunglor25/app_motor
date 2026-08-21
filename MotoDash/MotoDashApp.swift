import SwiftUI

@main
struct MotoDashApp: App {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var mediaSessionReader = MediaSessionReader()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, mediaSessionReader: mediaSessionReader)
                .preferredColorScheme(.dark)
        }
    }
}
