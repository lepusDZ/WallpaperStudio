import Cocoa
import OSLog

@MainActor
final class WallpaperWindowManager: NSObject {

    private var windows: [NSWindow] = []

    private let developmentVideoURL = URL(
        fileURLWithPath:
            "/Users/lepus/Downloads/valley-misty-moewalls-com.mp4"
    )

    override init() {
        super.init()

        Logger.display.info(
            "WallpaperWindowManager initialized"
        )

        createWallpaperWindows()
        observeScreenChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Window Management

    /// Creates one wallpaper window for every connected display.
    private func createWallpaperWindows() {
        let screens = NSScreen.screens

        Logger.display.info(
            "Creating wallpaper windows for \(screens.count) display(s)"
        )

        for screen in screens {
            guard let window = makeWallpaperWindow(for: screen) else {
                continue
            }

            windows.append(window)
            window.orderFront(nil)

            Logger.display.info(
                """
                Wallpaper window shown on \
                \(screen.localizedName, privacy: .public)
                """
            )
        }
    }

    /// Stops playback and removes all wallpaper windows.
    private func removeWallpaperWindows() {
        Logger.display.info(
            "Removing \(self.windows.count) wallpaper window(s)"
        )

        for window in windows {
            if let videoView = window.contentView as? VideoWallpaperView {
                videoView.pause()
            }

            window.orderOut(nil)
        }

        windows.removeAll()
    }

    /// Creates and configures a wallpaper window for one display.
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

        // Keep the wallpaper across Spaces and stationary in Mission Control.
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true

        // Keep the wallpaper underneath normal application windows.
        window.level = NSWindow.Level(
            rawValue: Int(
                CGWindowLevelForKey(.desktopWindow)
            )
        )

        // NSView coordinates are local to the window, unlike NSScreen.frame,
        // whose x/y coordinates belong to the global desktop.
        let contentFrame = NSRect(
            origin: .zero,
            size: screen.frame.size
        )

        do {
            let videoView = try VideoWallpaperView(
                frame: contentFrame,
                sourceURL: developmentVideoURL
            )

            videoView.autoresizingMask = [
                .width,
                .height
            ]

            window.contentView = videoView
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

        return window
    }

    // MARK: - Display Changes

    /// Watches for monitors being connected, disconnected, or reconfigured.
    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        Logger.display.debug(
            "Started observing display configuration changes"
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
