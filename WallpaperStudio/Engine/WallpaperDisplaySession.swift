import Cocoa

@MainActor
final class WallpaperDisplaySession {

    private(set)
    var display: DisplayDescriptor

    private let windowController:
        WallpaperWindowController

    init(
        display: DisplayDescriptor,
        screen: NSScreen,
        sourceURL: URL,
        scalingMode:
            WallpaperScalingMode
    ) throws {

        self.display = display

        windowController =
            try WallpaperWindowController(
                display:
                    display,
                screen:
                    screen,
                sourceURL:
                    sourceURL,
                scalingMode:
                    scalingMode
            )
    }

    func show(
        playing: Bool
    ) {
        windowController
            .showWallpaper(
                playing:
                    playing
            )
    }

    func pause() {
        windowController.pause()
    }

    func resume() {
        windowController.resume()
    }

    func stop() {
        windowController.stop()
    }

    func setScalingMode(
        _ mode:
            WallpaperScalingMode
    ) {
        windowController
            .setScalingMode(
                mode
            )
    }

    func update(
        display: DisplayDescriptor,
        screen: NSScreen
    ) {
        self.display = display

        windowController
            .updateDisplay(
                display,
                screen:
                    screen
            )
    }
}
