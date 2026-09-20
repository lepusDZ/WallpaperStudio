import Foundation
import OSLog

@MainActor
final class WallpaperEngine {

    private(set) var videoURL: URL?

    private var windowManager: WallpaperWindowManager?

    private(set) var state: WallpaperEngineState = .stopped

    private(set) var scalingMode: WallpaperScalingMode = .fill

    init() {
        Logger.engine.info(
            "WallpaperEngine initialized"
        )
    }

    // MARK: - Video Source

    @discardableResult
    func setVideoURL(
        _ url: URL
    ) -> Bool {
        guard state == .stopped else {
            Logger.engine.warning(
                "Video source can only be changed while stopped"
            )
            return false
        }

        videoURL = url

        Logger.engine.info(
            "Video source changed to \(url.lastPathComponent, privacy: .public)"
        )

        return true
    }

    func clearVideoURL() {
        guard state == .stopped else {
            return
        }

        videoURL = nil
    }

    // MARK: - Lifecycle

    @discardableResult
    func start() -> Bool {
        guard state == .stopped else {
            Logger.engine.debug(
                "Start ignored because engine is already \(self.state.rawValue, privacy: .public)"
            )
            return true
        }

        guard let videoURL else {
            Logger.engine.warning(
                "Start ignored because no wallpaper has been selected"
            )
            return false
        }

        Logger.engine.info(
            "Starting wallpaper engine"
        )

        let manager = WallpaperWindowManager(
            videoURL: videoURL,
            scalingMode: scalingMode
        )

        guard manager.start() else {
            Logger.engine.error(
                "Wallpaper engine failed to start"
            )
            return false
        }

        windowManager = manager
        state = .running

        Logger.engine.info(
            "Wallpaper engine started"
        )

        return true
    }

    func pause() {
        guard state == .running else {
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
            return
        }

        Logger.engine.info(
            "Stopping wallpaper engine"
        )

        windowManager?.stop()
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
