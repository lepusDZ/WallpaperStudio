import Foundation
import OSLog

enum WallpaperEngineState: String {
    case stopped
    case running
    case paused
}

@MainActor
final class WallpaperEngine {

    private let videoURL: URL

    private var windowManager: WallpaperWindowManager?

    private(set) var state: WallpaperEngineState = .stopped

    private(set) var scalingMode: WallpaperScalingMode = .fill

    init(
        videoURL: URL = DevelopmentAssets.videoURL
    ) {
        self.videoURL = videoURL

        Logger.engine.info("WallpaperEngine initialized")
    }

    // MARK: - Lifecycle

    func start() {
        guard state == .stopped else {
            Logger.engine.debug(
                "Start ignored because engine is already \(self.state.rawValue, privacy: .public)"
            )
            return
        }

        Logger.engine.info("Starting wallpaper engine")

        let manager = WallpaperWindowManager(
            videoURL: videoURL,
            scalingMode: scalingMode
        )

        guard manager.start() else {
            Logger.engine.error(
                "Wallpaper engine failed to start"
            )
            return
        }

        windowManager = manager
        state = .running

        Logger.engine.info(
            "Wallpaper engine started"
        )
    }

    func pause() {
        guard state == .running else {
            Logger.engine.debug(
                "Pause ignored because engine is \(self.state.rawValue, privacy: .public)"
            )
            return
        }

        windowManager?.pause()

        state = .paused

        Logger.engine.info(
            "Wallpaper engine paused"
        )
    }

    func resume() {
        guard state == .paused else {
            Logger.engine.debug(
                "Resume ignored because engine is \(self.state.rawValue, privacy: .public)"
            )
            return
        }

        windowManager?.resume()

        state = .running

        Logger.engine.info(
            "Wallpaper engine resumed"
        )
    }

    func stop() {
        guard state != .stopped else {
            Logger.engine.debug(
                "Stop ignored because engine is already stopped"
            )
            return
        }

        Logger.engine.info(
            "Stopping wallpaper engine"
        )

        windowManager?.stop()

        // Removing our strong reference allows the manager and everything
        // it owns to be released once no other references remain.
        windowManager = nil

        state = .stopped

        Logger.engine.info(
            "Wallpaper engine stopped"
        )
    }

    // MARK: - Configuration

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        guard scalingMode != mode else {
            return
        }

        scalingMode = mode

        windowManager?.setScalingMode(mode)

        Logger.engine.info(
            "Scaling mode changed to \(mode.displayName, privacy: .public)"
        )
    }
}
