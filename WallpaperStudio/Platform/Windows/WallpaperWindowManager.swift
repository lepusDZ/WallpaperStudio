import Cocoa
import OSLog

@MainActor
final class WallpaperWindowManager: NSObject {

    private var windows: [NSWindow] = []

    private let debugColors: [NSColor] = [
        .orange,
        .gray,
        .green,
        .blue,
        .red,
        .black,
        .purple,
        .cyan
    ]

    override init() {
        super.init()

        Logger.display.info("WallpaperWindowManager initialized")

        createWallpaperWindows()
        observeScreenChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Creates one wallpaper window for every currently connected display.
    private func createWallpaperWindows() {
        let screens = NSScreen.screens

        Logger.display.info(
            "Creating wallpaper windows for \(screens.count) display(s)"
        )

        for (index, screen) in screens.enumerated() {
            let color = debugColors[index % debugColors.count]

            let window = makeWallpaperWindow(
                for: screen,
                color: color
            )

            windows.append(window)
            window.orderFront(nil)

            Logger.display.info(
                "Wallpaper window shown on \(screen.localizedName, privacy: .public)"
            )
        }
    }

    /// Removes all currently managed wallpaper windows.
    private func removeWallpaperWindows() {
        Logger.display.info(
            "Removing \(self.windows.count) wallpaper window(s)"
        )

        for window in windows {
            window.orderOut(nil)
        }

        windows.removeAll()
    }

    /// Creates and configures one wallpaper window for a specific display.
    private func makeWallpaperWindow(
        for screen: NSScreen,
        color: NSColor
    ) -> NSWindow {

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

        // Make the window behave like part of the desktop rather
        // than a normal application window.
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        window.backgroundColor = color
        window.hasShadow = false
        window.ignoresMouseEvents = true

        window.level = NSWindow.Level(
            rawValue: Int(
                CGWindowLevelForKey(.desktopWindow)
            )
        )

        return window
    }

    /// Starts listening for display configuration changes.
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

    /// Called when displays are connected, disconnected,
    /// rearranged, or otherwise reconfigured.
    @objc
    private func screenConfigurationDidChange() {
        Logger.display.info(
            "Display configuration changed"
        )

        removeWallpaperWindows()
        createWallpaperWindows()
    }
}
