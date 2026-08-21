// Platform limitation: Android reads now-playing metadata from ANY app system-wide
// via NotificationListenerService; iOS has no public equivalent, so this only
// works with the built-in Apple Music app (MPMusicPlayerController.systemMusicPlayer),
// not Spotify/YouTube/etc.
import MediaPlayer
import UIKit

@MainActor
final class MediaSessionReader: ObservableObject {
    private let player = MPMusicPlayerController.systemMusicPlayer

    func isAuthorized() -> Bool {
        MPMediaLibrary.authorizationStatus() == .authorized
    }

    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }

    func getPlayingInfo() -> NowPlayingInfo {
        guard isAuthorized(), let item = player.nowPlayingItem else { return NowPlayingInfo() }
        let albumArt: String? = item.artwork.flatMap { artwork -> String? in
            guard let image = artwork.image(at: CGSize(width: 120, height: 120)),
                  let data = image.jpegData(compressionQuality: 0.7)
            else { return nil }
            return "data:image/jpeg;base64," + data.base64EncodedString()
        }
        return NowPlayingInfo(
            title: item.title ?? "",
            artist: item.artist ?? "",
            album: item.albumTitle ?? "",
            albumArt: albumArt,
            packageName: "com.apple.Music",
            isPlaying: player.playbackState == .playing
        )
    }

    func play() { player.play() }
    func pause() { player.pause() }
    func next() { player.skipToNextItem() }
    func prev() { player.skipToPreviousItem() }
}
