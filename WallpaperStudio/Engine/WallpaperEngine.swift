import Foundation
import OSLog
import Cocoa

@MainActor
final class WallpaperEngine {

    private(set)
    var videoURL: URL?

    private let displayManager:
        DisplayManager

    private var displaySessions:
        [DisplayID: WallpaperDisplaySession] = [:]

    private(set)
    var state:
        WallpaperEngineState = .stopped

    private(set)
    var scalingMode:
        WallpaperScalingMode = .fill

    init(
        displayManager:
            DisplayManager = DisplayManager()
    ) {
        self.displayManager =
            displayManager

        displayManager.onTopologyChange = {
            [weak self] change in

            self?.handleTopologyChange(
                change
            )
        }

        Logger.engine.info(
            "WallpaperEngine initialized"
        )
    }

    // MARK: - Display Discovery

    func startDisplayMonitoring() {
        displayManager.start()
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

        startDisplayMonitoring()

        Logger.engine.info(
            "Starting wallpaper engine for \(self.displayManager.displays.count) display(s)"
        )

        createMissingSessions(
            for:
                displayManager.displays,
            sourceURL:
                videoURL,
            playing:
                true
        )

        guard !displaySessions.isEmpty
        else {
            Logger.engine.error(
                "Wallpaper engine failed to create any display sessions"
            )
            return false
        }

        state = .running

        Logger.engine.info(
            "Wallpaper engine started with \(self.displaySessions.count) display session(s)"
        )

        return true
    }

    func pause() {
        guard state == .running else {
            return
        }

        for session
            in displaySessions.values {

            session.pause()
        }

        state = .paused

        Logger.engine.info(
            "Wallpaper engine paused"
        )
    }

    func resume() {
        guard state == .paused else {
            return
        }

        for session
            in displaySessions.values {

            session.resume()
        }

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

        for session
            in displaySessions.values {

            session.stop()
        }

        displaySessions.removeAll()

        state = .stopped

        Logger.engine.info(
            "Wallpaper engine stopped"
        )
    }

    // MARK: - Configuration

    func setScalingMode(
        _ mode:
            WallpaperScalingMode
    ) {
        guard scalingMode != mode else {
            return
        }

        scalingMode = mode

        for session
            in displaySessions.values {

            session.setScalingMode(
                mode
            )
        }

        Logger.engine.info(
            "Scaling mode changed to \(mode.displayName, privacy: .public)"
        )
    }

    // MARK: - Display Sessions

    private func handleTopologyChange(
        _ change:
            DisplayTopologyChange
    ) {
        Logger.engine.info(
            "Handling display topology change"
        )

        guard state != .stopped,
              let videoURL
        else {
            return
        }

        reconcileSessions(
            with:
                change.current,
            sourceURL:
                videoURL
        )
    }

    private func reconcileSessions(
        with displays:
            [DisplayDescriptor],
        sourceURL: URL
    ) {
        let currentIDs =
            Set(
                displays.map(
                    \.id
                )
            )

        let removedIDs =
            displaySessions.keys
                .filter {
                    !currentIDs
                        .contains($0)
                }

        for displayID
            in removedIDs {

            guard let session =
                displaySessions
                    .removeValue(
                        forKey:
                            displayID
                    )
            else {
                continue
            }

            Logger.engine.info(
                "Removing wallpaper session for display \(displayID.rawValue, privacy: .public)"
            )

            session.stop()
        }

        for display in displays {
            guard let screen =
                displayManager.screen(
                    for:
                        display.id
                )
            else {
                Logger.display.error(
                    "Could not resolve NSScreen for display \(display.id.rawValue, privacy: .public)"
                )
                continue
            }

            if let session =
                displaySessions[
                    display.id
                ] {

                session.update(
                    display:
                        display,
                    screen:
                        screen
                )

                continue
            }

            createSession(
                for:
                    display,
                screen:
                    screen,
                sourceURL:
                    sourceURL,
                playing:
                    state == .running
            )
        }
    }

    private func createMissingSessions(
        for displays:
            [DisplayDescriptor],
        sourceURL: URL,
        playing: Bool
    ) {
        for display in displays {
            guard displaySessions[
                display.id
            ] == nil
            else {
                continue
            }

            guard let screen =
                displayManager.screen(
                    for:
                        display.id
                )
            else {
                Logger.display.error(
                    "Could not resolve NSScreen for display \(display.id.rawValue, privacy: .public)"
                )
                continue
            }

            createSession(
                for:
                    display,
                screen:
                    screen,
                sourceURL:
                    sourceURL,
                playing:
                    playing
            )
        }
    }

    private func createSession(
        for display:
            DisplayDescriptor,
        screen: NSScreen,
        sourceURL: URL,
        playing: Bool
    ) {
        do {
            let session =
                try WallpaperDisplaySession(
                    display:
                        display,
                    screen:
                        screen,
                    sourceURL:
                        sourceURL,
                    scalingMode:
                        scalingMode
                )

            displaySessions[
                display.id
            ] = session

            session.show(
                playing:
                    playing
            )

            Logger.engine.info(
                "Created wallpaper session for \(display.name, privacy: .public) [\(display.id.rawValue, privacy: .public)]"
            )
        } catch {
            Logger.engine.error(
                "Failed to create wallpaper session for \(display.name, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
