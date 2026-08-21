import Foundation

struct NowPlayingInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var albumArt: String? // "data:image/jpeg;base64,..." or nil
    var packageName: String = ""
    var isPlaying: Bool = false
}
