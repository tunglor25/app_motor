import SwiftUI
import UIKit

/// Native port of race.html's music FAB/popup: polls MediaSessionReader every
/// 2s, shows a floating button only while something with a title is
/// playing/paused. See Music/MediaSessionReader.swift for the platform
/// limitation this now covers (Apple Music only, not system-wide like Android).
struct MusicWidget: View {
    @ObservedObject var reader: MediaSessionReader

    @State private var info = NowPlayingInfo()
    @State private var showPopup = false

    var body: some View {
        Group {
            if !info.title.isEmpty {
                ZStack {
                    MusicFab(onClick: { showPopup = true })
                    if showPopup {
                        MusicPopup(
                            info: info,
                            onDismiss: { showPopup = false },
                            onTogglePlay: {
                                if info.isPlaying { reader.pause() } else { reader.play() }
                                Task {
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    info = reader.getPlayingInfo()
                                }
                            },
                            onPrev: { reader.prev() },
                            onNext: { reader.next() }
                        )
                    }
                }
            }
        }
        .task {
            while !Task.isCancelled {
                info = reader.getPlayingInfo()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
}

private struct MusicFab: View {
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text("\u{1F3B5}")
                .font(.system(size: 20))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
    }
}

private struct MusicPopup: View {
    let info: NowPlayingInfo
    let onDismiss: () -> Void
    let onTogglePlay: () -> Void
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 8) {
                if let art = Self.decodeDataUri(info.albumArt) {
                    Image(uiImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 120, height: 120)
                }

                Text(info.title)
                    .foregroundColor(.white)
                    .font(DashFont.shareTechMono(16))
                    .padding(.top, 12)
                Text(info.artist)
                    .foregroundColor(.dashDim)
                    .font(DashFont.shareTechMono(12))

                HStack(spacing: 24) {
                    Button(action: onPrev) {
                        Text("\u{23EE}").font(.system(size: 24)).foregroundColor(.white)
                    }
                    Button(action: onTogglePlay) {
                        Text(info.isPlaying ? "\u{23F8}" : "\u{25B6}")
                            .font(.system(size: 24))
                            .foregroundColor(.dashCyan)
                    }
                    Button(action: onNext) {
                        Text("\u{23ED}").font(.system(size: 24)).foregroundColor(.white)
                    }
                }
                .padding(.top, 16)
            }
            .padding(20)
            .background(Color(argb: 0xFF0D0F14))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(24)
        }
    }

    private static func decodeDataUri(_ dataUri: String?) -> UIImage? {
        guard let dataUri, !dataUri.isEmpty else { return nil }
        guard let commaIndex = dataUri.firstIndex(of: ",") else { return nil }
        let base64 = String(dataUri[dataUri.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}
