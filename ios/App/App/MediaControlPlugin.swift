import Foundation
import UIKit
import Capacitor

/**
 * Reads "now playing" info from ANY app (Spotify, YouTube Music, Apple Music, ...) using
 * the private MediaRemote.framework via dlopen/dlsym, the same technique used by
 * community "Now Playing" widget projects. This is undocumented, unsupported by Apple,
 * and could stop working on a future iOS release — acceptable here only because this
 * build is sideloaded for personal use, never submitted to the App Store.
 *
 * JS-facing shape matches the Android MediaControlPlugin (getPlayingInfo/play/pause/next/prev)
 * so race.html/daily.html/classic.html work unchanged on both platforms.
 */
@objc(MediaControlPlugin)
public class MediaControlPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MediaControlPlugin"
    public let jsName = "MediaControlPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getPlayingInfo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pause", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "next", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "prev", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isNotificationAccessGranted", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openNotificationAccessSettings", returnType: CAPPluginReturnPromise)
    ]

    private typealias GetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias GetIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias SendCommandFn = @convention(c) (Int, [String: Any]?) -> Bool

    // Reverse-engineered MRMediaRemoteCommand values (stable across iOS releases so far).
    private enum MRCommand: Int {
        case play = 0
        case pause = 1
        case nextTrack = 4
        case previousTrack = 5
    }

    private static let handle: UnsafeMutableRawPointer? =
        dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)

    private static let getNowPlayingInfo: GetNowPlayingInfoFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { return nil }
        return unsafeBitCast(sym, to: GetNowPlayingInfoFn.self)
    }()

    private static let getIsPlaying: GetIsPlayingFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") else { return nil }
        return unsafeBitCast(sym, to: GetIsPlayingFn.self)
    }()

    private static let sendCommand: SendCommandFn? = {
        guard let handle, let sym = dlsym(handle, "MRMediaRemoteSendCommand") else { return nil }
        return unsafeBitCast(sym, to: SendCommandFn.self)
    }()

    private static func emptyInfo() -> PluginCallResultData {
        ["title": "", "artist": "", "album": "", "albumArt": "", "packageName": "", "isPlaying": false]
    }

    @objc func getPlayingInfo(_ call: CAPPluginCall) {
        guard let getNowPlayingInfo = MediaControlPlugin.getNowPlayingInfo else {
            call.resolve(MediaControlPlugin.emptyInfo())
            return
        }
        getNowPlayingInfo(DispatchQueue.main) { info in
            var result: PluginCallResultData = [
                "title": info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "",
                "artist": info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "",
                "album": info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "",
                "albumArt": "",
                "packageName": "",
                "isPlaying": false
            ]
            if let artData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
               let image = UIImage(data: artData),
               let jpegData = image.jpegData(compressionQuality: 0.7) {
                result["albumArt"] = jpegData.base64EncodedString()
            }
            guard let getIsPlaying = MediaControlPlugin.getIsPlaying else {
                call.resolve(result)
                return
            }
            getIsPlaying(DispatchQueue.main) { playing in
                result["isPlaying"] = playing
                call.resolve(result)
            }
        }
    }

    @objc func play(_ call: CAPPluginCall) {
        _ = MediaControlPlugin.sendCommand?(MRCommand.play.rawValue, nil)
        call.resolve()
    }

    @objc func pause(_ call: CAPPluginCall) {
        _ = MediaControlPlugin.sendCommand?(MRCommand.pause.rawValue, nil)
        call.resolve()
    }

    @objc func next(_ call: CAPPluginCall) {
        _ = MediaControlPlugin.sendCommand?(MRCommand.nextTrack.rawValue, nil)
        call.resolve()
    }

    @objc func prev(_ call: CAPPluginCall) {
        _ = MediaControlPlugin.sendCommand?(MRCommand.previousTrack.rawValue, nil)
        call.resolve()
    }

    // iOS has no equivalent "notification access" gate for MediaRemote — resolve based on
    // whether the private framework/symbols loaded at all, so the Settings row degrades
    // gracefully instead of showing a broken permission prompt.
    @objc func isNotificationAccessGranted(_ call: CAPPluginCall) {
        call.resolve(["granted": MediaControlPlugin.getNowPlayingInfo != nil])
    }

    @objc func openNotificationAccessSettings(_ call: CAPPluginCall) {
        call.resolve()
    }
}
