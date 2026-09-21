import Cocoa

@MainActor
final class WallpaperDisplaySession {

    private(set) var display: DisplayDescriptor
    private(set) var wallpaper: Wallpaper

    private let windowController: WallpaperWindowController

    private var globalPlaybackEnabled = false

    private(set) var isIndividuallyPaused = false

    init(
        display: DisplayDescriptor,
        screen: NSScreen,
        wallpaper: Wallpaper,
        scalingMode: WallpaperScalingMode
    ) throws {
        self.display = display
        self.wallpaper = wallpaper

        windowController = try WallpaperWindowController(
            display: display,
            screen: screen,
            sourceURL: wallpaper.sourceURL,
            scalingMode: scalingMode
        )
    }

    // MARK: - Lifecycle

    func show(
        globalPlaybackEnabled: Bool
    ) {
        windowController.showWallpaper(
            playing: false
        )

        setGlobalPlaybackEnabled(
            globalPlaybackEnabled
        )
    }

    func setGlobalPlaybackEnabled(
        _ enabled: Bool
    ) {
        globalPlaybackEnabled = enabled
        updatePlayback()
    }

    func pauseIndependently() {
        guard !isIndividuallyPaused else {
            return
        }

        isIndividuallyPaused = true
        updatePlayback()
    }

    func resumeIndependently() {
        guard isIndividuallyPaused else {
            return
        }

        isIndividuallyPaused = false
        updatePlayback()
    }

    func stop() {
        windowController.stop()
    }

    // MARK: - Configuration

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        windowController.setScalingMode(
            mode
        )
    }

    func update(
        display: DisplayDescriptor,
        screen: NSScreen
    ) {
        self.display = display

        windowController.updateDisplay(
            display,
            screen: screen
        )
    }

    // MARK: - Playback

    private func updatePlayback() {
        let shouldPlay =
            globalPlaybackEnabled
            && !isIndividuallyPaused

        if shouldPlay {
            windowController.resume()
        } else {
            windowController.pause()
        }
    }
}
