import Combine
import Foundation
import OSLog
import Cocoa

@MainActor
final class WallpaperEngine: ObservableObject {

    private let displayManager: DisplayManager

    private var displaySessions:
        [DisplayID: WallpaperDisplaySession] = [:]

    // Used by the existing performance benchmark so it can temporarily
    // run the same video on every display without destroying assignments.
    private var uniformWallpaperOverride: Wallpaper?

    @Published
    private(set) var displays:
        [DisplayDescriptor] = []

    @Published
    private(set) var wallpaperAssignments:
        [DisplayID: Wallpaper] = [:]

    @Published
    private(set) var pausedDisplayIDs:
        Set<DisplayID> = []

    @Published
    private(set) var state: WallpaperEngineState = .stopped

    @Published
    private(set) var scalingMode:
        WallpaperScalingMode = .fill

    /// Compatibility with the Day 9 benchmark.
    /// Normal app usage should use per-display assignments instead.
    var videoURL: URL? {
        uniformWallpaperOverride?.sourceURL
    }

    var hasAnyWallpaperAssignment: Bool {
        uniformWallpaperOverride != nil
        || !wallpaperAssignments.isEmpty
    }

    init(
        displayManager: DisplayManager = DisplayManager()
    ) {
        self.displayManager = displayManager

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

        displays = displayManager.displays
    }

    // MARK: - Wallpaper Assignment

    @discardableResult
    func assignWallpaper(
        _ wallpaper: Wallpaper,
        to displayID: DisplayID
    ) -> Bool {
        guard displays.contains(
            where: {
                $0.id == displayID
            }
        ) else {
            Logger.engine.error(
                "Cannot assign wallpaper because display \(displayID.rawValue, privacy: .public) is not connected"
            )
            return false
        }

        // A user-selected per-display assignment takes us out of the
        // temporary uniform benchmark mode.
        uniformWallpaperOverride = nil

        wallpaperAssignments[
            displayID
        ] = wallpaper

        Logger.engine.info(
            "Assigned \(wallpaper.displayName, privacy: .public) to display \(displayID.rawValue, privacy: .public)"
        )

        if state != .stopped {
            replaceSession(
                for: displayID
            )
        }

        return true
    }

    func clearWallpaper(
        for displayID: DisplayID
    ) {
        uniformWallpaperOverride = nil

        wallpaperAssignments.removeValue(
            forKey: displayID
        )

        pausedDisplayIDs.remove(
            displayID
        )

        if let session =
            displaySessions.removeValue(
                forKey: displayID
            ) {

            session.stop()
        }

        Logger.engine.info(
            "Cleared wallpaper assignment for display \(displayID.rawValue, privacy: .public)"
        )
    }

    // MARK: - Uniform Video Compatibility

    /// Used by the existing performance benchmark.
    /// This does not overwrite the normal per-display assignment dictionary.
    @discardableResult
    func setVideoURL(
        _ url: URL
    ) -> Bool {
        guard state == .stopped else {
            Logger.engine.warning(
                "Uniform video source can only be changed while stopped"
            )
            return false
        }

        uniformWallpaperOverride =
            Wallpaper(
                sourceURL: url
            )

        Logger.engine.info(
            "Temporary uniform wallpaper set to \(url.lastPathComponent, privacy: .public)"
        )

        return true
    }

    func clearVideoURL() {
        guard state == .stopped else {
            return
        }

        uniformWallpaperOverride = nil
    }

    // MARK: - Global Lifecycle

    @discardableResult
    func start() -> Bool {
        guard state == .stopped else {
            Logger.engine.debug(
                "Start ignored because engine is already \(self.state.rawValue, privacy: .public)"
            )
            return true
        }

        startDisplayMonitoring()

        guard hasAnyWallpaperAssignment else {
            Logger.engine.warning(
                "Start ignored because no wallpapers have been assigned"
            )
            return false
        }

        Logger.engine.info(
            "Starting wallpaper engine for \(self.displays.count) display(s)"
        )

        createMissingSessions(
            for: displays,
            globalPlaybackEnabled: true
        )

        guard !displaySessions.isEmpty else {
            Logger.engine.error(
                "Wallpaper engine could not create any display sessions"
            )
            return false
        }

        state = .running

        Logger.engine.info(
            "Wallpaper engine started with \(self.displaySessions.count) session(s)"
        )

        return true
    }

    func pause() {
        guard state == .running else {
            return
        }

        state = .paused

        for session in displaySessions.values {
            session.setGlobalPlaybackEnabled(
                false
            )
        }

        Logger.engine.info(
            "Wallpaper engine paused"
        )
    }

    func resume() {
        guard state == .paused else {
            return
        }

        state = .running

        for session in displaySessions.values {
            session.setGlobalPlaybackEnabled(
                true
            )
        }

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

        for session in displaySessions.values {
            session.stop()
        }

        displaySessions.removeAll()
        pausedDisplayIDs.removeAll()

        state = .stopped

        Logger.engine.info(
            "Wallpaper engine stopped"
        )
    }

    // MARK: - Per-Display Lifecycle

    func pauseDisplay(
        _ displayID: DisplayID
    ) {
        guard let session =
            displaySessions[
                displayID
            ]
        else {
            return
        }

        guard pausedDisplayIDs.insert(
            displayID
        ).inserted else {
            return
        }

        session.pauseIndependently()

        Logger.engine.info(
            "Paused wallpaper on display \(displayID.rawValue, privacy: .public)"
        )
    }

    func resumeDisplay(
        _ displayID: DisplayID
    ) {
        guard let session =
            displaySessions[
                displayID
            ]
        else {
            return
        }

        guard pausedDisplayIDs.remove(
            displayID
        ) != nil else {
            return
        }

        session.resumeIndependently()

        Logger.engine.info(
            "Resumed wallpaper on display \(displayID.rawValue, privacy: .public)"
        )
    }

    // MARK: - Scaling

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        guard scalingMode != mode else {
            return
        }

        scalingMode = mode

        for session in displaySessions.values {
            session.setScalingMode(
                mode
            )
        }

        Logger.engine.info(
            "Scaling mode changed to \(mode.displayName, privacy: .public)"
        )
    }

    // MARK: - Topology

    private func handleTopologyChange(
        _ change: DisplayTopologyChange
    ) {
        displays = change.current

        Logger.engine.info(
            "Handling display topology change"
        )

        guard state != .stopped else {
            return
        }

        reconcileSessions(
            with: change.current
        )
    }

    private func reconcileSessions(
        with currentDisplays: [DisplayDescriptor]
    ) {
        let connectedIDs =
            Set(
                currentDisplays.map(
                    \.id
                )
            )

        let disconnectedIDs =
            displaySessions.keys
                .filter {
                    !connectedIDs.contains(
                        $0
                    )
                }

        for displayID in disconnectedIDs {
            guard let session =
                displaySessions.removeValue(
                    forKey: displayID
                )
            else {
                continue
            }

            session.stop()

            Logger.engine.info(
                "Removed wallpaper session for disconnected display \(displayID.rawValue, privacy: .public)"
            )
        }

        for display in currentDisplays {
            guard let screen =
                displayManager.screen(
                    for: display.id
                )
            else {
                continue
            }

            if let session =
                displaySessions[
                    display.id
                ] {

                session.update(
                    display: display,
                    screen: screen
                )

                continue
            }

            guard effectiveWallpaper(
                for: display.id
            ) != nil else {
                continue
            }

            createSession(
                for: display,
                screen: screen,
                globalPlaybackEnabled:
                    state == .running
            )
        }
    }

    // MARK: - Sessions

    private func createMissingSessions(
        for currentDisplays: [DisplayDescriptor],
        globalPlaybackEnabled: Bool
    ) {
        for display in currentDisplays {
            guard displaySessions[
                display.id
            ] == nil else {
                continue
            }

            guard effectiveWallpaper(
                for: display.id
            ) != nil else {
                continue
            }

            guard let screen =
                displayManager.screen(
                    for: display.id
                )
            else {
                Logger.display.error(
                    "Could not resolve NSScreen for \(display.id.rawValue, privacy: .public)"
                )
                continue
            }

            createSession(
                for: display,
                screen: screen,
                globalPlaybackEnabled:
                    globalPlaybackEnabled
            )
        }
    }

    private func replaceSession(
        for displayID: DisplayID
    ) {
        guard let display =
            displays.first(
                where: {
                    $0.id == displayID
                }
            ),
            let screen =
                displayManager.screen(
                    for: displayID
                ),
            effectiveWallpaper(
                for: displayID
            ) != nil
        else {
            return
        }

        let wasIndividuallyPaused =
            pausedDisplayIDs.contains(
                displayID
            )

        if let oldSession =
            displaySessions.removeValue(
                forKey: displayID
            ) {

            oldSession.stop()
        }

        createSession(
            for: display,
            screen: screen,
            globalPlaybackEnabled:
                state == .running,
            individuallyPaused:
                wasIndividuallyPaused
        )
    }

    private func createSession(
        for display: DisplayDescriptor,
        screen: NSScreen,
        globalPlaybackEnabled: Bool,
        individuallyPaused: Bool? = nil
    ) {
        guard let wallpaper =
            effectiveWallpaper(
                for: display.id
            )
        else {
            return
        }

        do {
            let session =
                try WallpaperDisplaySession(
                    display: display,
                    screen: screen,
                    wallpaper: wallpaper,
                    scalingMode: scalingMode
                )

            displaySessions[
                display.id
            ] = session

            let shouldPauseIndividually =
                individuallyPaused
                ?? pausedDisplayIDs.contains(
                    display.id
                )

            if shouldPauseIndividually {
                pausedDisplayIDs.insert(
                    display.id
                )

                session.pauseIndependently()
            }

            session.show(
                globalPlaybackEnabled:
                    globalPlaybackEnabled
            )

            Logger.engine.info(
                """
                Created wallpaper session for \
                \(display.name, privacy: .public) using \
                \(wallpaper.displayName, privacy: .public)
                """
            )
        } catch {
            Logger.engine.error(
                """
                Failed to create wallpaper session for \
                \(display.name, privacy: .public): \
                \(error.localizedDescription, privacy: .public)
                """
            )
        }
    }

    private func effectiveWallpaper(
        for displayID: DisplayID
    ) -> Wallpaper? {
        if let uniformWallpaperOverride {
            return uniformWallpaperOverride
        }

        return wallpaperAssignments[
            displayID
        ]
    }
}
