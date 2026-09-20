import Cocoa
import OSLog

@MainActor
final class WallpaperWindowManager: NSObject {

    private let videoURL: URL

    private var windows: [NSWindow] = []

    private var isObservingScreenChanges = false
    private var isPaused = false

    private(set) var scalingMode: WallpaperScalingMode

    init(
        videoURL: URL,
        scalingMode: WallpaperScalingMode
    ) {
        self.videoURL = videoURL
        self.scalingMode = scalingMode

        super.init()

        Logger.display.info(
            "WallpaperWindowManager initialized"
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        Logger.display.debug(
            "WallpaperWindowManager released"
        )
    }

    // MARK: - Lifecycle

    func start() -> Bool {
        guard windows.isEmpty else {
            Logger.display.debug(
                "Window manager start ignored because windows already exist"
            )
            return true
        }

        isPaused = false

        createWallpaperWindows()

        guard !windows.isEmpty else {
            Logger.display.error(
                "No wallpaper windows could be created"
            )
            return false
        }

        observeScreenChanges()

        return true
    }

    func pause() {
        guard !isPaused else {
            return
        }

        isPaused = true

        Logger.display.info(
            "Pausing wallpaper windows"
        )

        for window in windows {
            guard let videoView =
                window.contentView as? VideoWallpaperView
            else {
                continue
            }

            videoView.pause()
        }
    }

    func resume() {
        guard isPaused else {
            return
        }

        isPaused = false

        Logger.display.info(
            "Resuming wallpaper windows"
        )

        for window in windows {
            guard let videoView =
                window.contentView as? VideoWallpaperView
            else {
                continue
            }

            videoView.resume()
        }
    }

    func stop() {
        Logger.display.info(
            "Stopping wallpaper windows"
        )

        stopObservingScreenChanges()
        removeWallpaperWindows()

        isPaused = false
    }

    // MARK: - Scaling

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        guard scalingMode != mode else {
            return
        }

        scalingMode = mode

        for window in windows {
            guard let videoView =
                window.contentView as? VideoWallpaperView
            else {
                continue
            }

            videoView.scalingMode = mode
        }
    }

    // MARK: - Window Management

    private func createWallpaperWindows() {
        let screens = NSScreen.screens

        Logger.display.info(
            "Creating wallpaper windows for \(screens.count) display(s)"
        )

        for screen in screens {
            guard let window =
                makeWallpaperWindow(for: screen)
            else {
                continue
            }

            windows.append(window)
            window.orderFront(nil)

            Logger.display.info(
                "Wallpaper window shown on \(screen.localizedName, privacy: .public)"
            )
        }
    }

    private func removeWallpaperWindows() {
        Logger.display.info(
            "Removing \(self.windows.count) wallpaper window(s)"
        )

        for window in windows {
            if let videoView =
                window.contentView as? VideoWallpaperView {

                videoView.stop()
            }

            window.contentView = nil
            window.close()
        }

        windows.removeAll()
    }

    private func makeWallpaperWindow(
        for screen: NSScreen
    ) -> NSWindow? {
        Logger.display.debug(
            "Creating window for \(screen.localizedName, privacy: .public)"
        )

        Logger.display.debug(
            """
            Display frame: \
            x=\(screen.frame.origin.x), \
            y=\(screen.frame.origin.y), \
            width=\(screen.frame.width), \
            height=\(screen.frame.height)
            """
        )

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Swift ARC owns the NSWindow through our windows array.
        window.isReleasedWhenClosed = false

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true

        window.level = NSWindow.Level(
            rawValue: Int(
                CGWindowLevelForKey(.desktopWindow)
            )
        )

        let contentFrame = NSRect(
            origin: .zero,
            size: screen.frame.size
        )

        do {
            let videoView = try VideoWallpaperView(
                frame: contentFrame,
                sourceURL: videoURL,
                scalingMode: scalingMode
            )

            videoView.autoresizingMask = [
                .width,
                .height
            ]

            window.contentView = videoView

            if !isPaused {
                videoView.resume()
            }

            return window
        } catch {
            Logger.rendering.error(
                """
                Failed to create video wallpaper for \
                \(screen.localizedName, privacy: .public): \
                \(error.localizedDescription, privacy: .public)
                """
            )

            return nil
        }
    }

    // MARK: - Display Changes

    private func observeScreenChanges() {
        guard !isObservingScreenChanges else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        isObservingScreenChanges = true

        Logger.display.debug(
            "Started observing display configuration changes"
        )
    }

    private func stopObservingScreenChanges() {
        guard isObservingScreenChanges else {
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        isObservingScreenChanges = false

        Logger.display.debug(
            "Stopped observing display configuration changes"
        )
    }

    @objc
    private func screenConfigurationDidChange() {
        Logger.display.info(
            "Display configuration changed"
        )

        removeWallpaperWindows()
        createWallpaperWindows()
    }
}
