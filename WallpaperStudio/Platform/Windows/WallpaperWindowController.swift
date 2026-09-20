import Cocoa
import OSLog

@MainActor
final class WallpaperWindowController:
    NSWindowController {

    let displayID: DisplayID

    private let videoView:
        VideoWallpaperView

    private var isStopped = false

    init(
        display: DisplayDescriptor,
        screen: NSScreen,
        sourceURL: URL,
        scalingMode:
            WallpaperScalingMode
    ) throws {

        let contentFrame =
            NSRect(
                origin: .zero,
                size:
                    screen.frame.size
            )

        let videoView =
            try VideoWallpaperView(
                frame:
                    contentFrame,
                sourceURL:
                    sourceURL,
                scalingMode:
                    scalingMode
            )

        videoView.autoresizingMask = [
            .width,
            .height
        ]

        let window =
            NSWindow(
                contentRect:
                    screen.frame,
                styleMask:
                    [.borderless],
                backing:
                    .buffered,
                defer:
                    false
            )

        window.isReleasedWhenClosed =
            false

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        window.backgroundColor =
            .black

        window.hasShadow = false

        window.ignoresMouseEvents =
            true

        window.level =
            NSWindow.Level(
                rawValue:
                    Int(
                        CGWindowLevelForKey(
                            .desktopWindow
                        )
                    )
            )

        window.contentView =
            videoView

        self.displayID =
            display.id

        self.videoView =
            videoView

        super.init(
            window: window
        )

        Logger.display.debug(
            "WallpaperWindowController created for \(display.name, privacy: .public) [\(display.id.rawValue, privacy: .public)]"
        )
    }

    required init?(coder: NSCoder) {
        fatalError(
            "WallpaperWindowController does not support NSCoder"
        )
    }

    deinit {
        Logger.display.debug(
            "WallpaperWindowController released for \(self.displayID.rawValue, privacy: .public)"
        )
    }

    // MARK: - Lifecycle

    func showWallpaper(
        playing: Bool
    ) {
        guard !isStopped else {
            return
        }

        window?.orderFront(nil)

        if playing {
            videoView.resume()
        }
    }

    func pause() {
        guard !isStopped else {
            return
        }

        videoView.pause()
    }

    func resume() {
        guard !isStopped else {
            return
        }

        videoView.resume()
    }

    func stop() {
        guard !isStopped else {
            return
        }

        isStopped = true

        videoView.stop()

        window?.contentView = nil
        window?.close()
    }

    // MARK: - Display Updates

    func updateDisplay(
        _ display: DisplayDescriptor,
        screen: NSScreen
    ) {
        guard display.id == displayID,
              !isStopped
        else {
            return
        }

        window?.setFrame(
            screen.frame,
            display: true
        )

        Logger.display.info(
            "Wallpaper surface updated for \(display.name, privacy: .public): \(NSStringFromRect(screen.frame), privacy: .public)"
        )
    }

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        guard !isStopped else {
            return
        }

        videoView.scalingMode = mode

        Logger.display.debug(
            "Scaling mode \(mode.displayName, privacy: .public) applied to display \(self.displayID.rawValue, privacy: .public)"
        )
    }
}
