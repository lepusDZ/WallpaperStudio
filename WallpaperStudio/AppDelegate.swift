import Cocoa
import OSLog
import UniformTypeIdentifiers

@MainActor
final class AppDelegate:
    NSObject,
    NSApplicationDelegate {

    let wallpaperEngine =
        WallpaperEngine()

    lazy var performanceBenchmark =
        DebugPerformanceBenchmark(
            engine: wallpaperEngine
        )

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Application finished launching"
        )

        wallpaperEngine
            .startDisplayMonitoring()
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Wallpaper Studio is terminating"
        )

        performanceBenchmark.cancel()
        wallpaperEngine.stop()
    }

    // MARK: - Wallpaper Assignment

    func chooseWallpaper(
        for displayID: DisplayID
    ) {
        let panel = NSOpenPanel()

        panel.title =
            "Choose Video Wallpaper"

        panel.prompt =
            "Choose"

        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.allowedContentTypes = [
            .movie
        ]

        guard
            panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        let wallpaper =
            Wallpaper(
                sourceURL: url
            )

        guard wallpaperEngine
            .assignWallpaper(
                wallpaper,
                to: displayID
            )
        else {
            return
        }

        Logger.engine.info(
            "Selected \(url.lastPathComponent, privacy: .public) for display \(displayID.rawValue, privacy: .public)"
        )
    }

    func clearWallpaper(
        for displayID: DisplayID
    ) {
        wallpaperEngine
            .clearWallpaper(
                for: displayID
            )
    }

    // MARK: - Global Controls

    func startWallpaper() {
        _ = wallpaperEngine.start()
    }

    func pauseWallpaper() {
        wallpaperEngine.pause()
    }

    func resumeWallpaper() {
        wallpaperEngine.resume()
    }

    func stopWallpaper() {
        wallpaperEngine.stop()
    }

    // MARK: - Per-Display Controls

    func pauseWallpaper(
        on displayID: DisplayID
    ) {
        wallpaperEngine
            .pauseDisplay(
                displayID
            )
    }

    func resumeWallpaper(
        on displayID: DisplayID
    ) {
        wallpaperEngine
            .resumeDisplay(
                displayID
            )
    }

    // MARK: - Configuration

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        wallpaperEngine
            .setScalingMode(
                mode
            )
    }

    // MARK: - Debug

    func runLifecycleStressTest() {
        Logger.engine.info(
            "Starting 20-cycle lifecycle stress test"
        )

        guard wallpaperEngine
            .hasAnyWallpaperAssignment
        else {
            Logger.engine.warning(
                "Lifecycle test requires at least one wallpaper assignment"
            )
            return
        }

        wallpaperEngine.stop()

        for iteration in 1...20 {
            Logger.engine.debug(
                "Lifecycle test iteration \(iteration)"
            )

            _ = wallpaperEngine.start()
            wallpaperEngine.pause()
            wallpaperEngine.resume()
            wallpaperEngine.stop()
        }

        Logger.engine.info(
            "20-cycle lifecycle stress test completed"
        )
    }
}
