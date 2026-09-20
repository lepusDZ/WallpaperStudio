import Cocoa
import OSLog
import UniformTypeIdentifiers

@MainActor
final class AppDelegate:
    NSObject,
    NSApplicationDelegate {

    private let wallpaperEngine =
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

        wallpaperEngine.startDisplayMonitoring()
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

    // MARK: - Wallpaper Selection

    func chooseWallpaper() -> URL? {
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
            return nil
        }

        let previousState =
            wallpaperEngine.state

        wallpaperEngine.stop()

        guard wallpaperEngine
            .setVideoURL(url)
        else {
            return nil
        }

        switch previousState {
        case .paused:
            _ = wallpaperEngine.start()
            wallpaperEngine.pause()

        case .running,
             .stopped:
            _ = wallpaperEngine.start()
        }

        Logger.engine.info(
            "Wallpaper selected: \(url.lastPathComponent, privacy: .public)"
        )

        return url
    }

    // MARK: - Wallpaper Controls

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

    func setScalingMode(
        _ mode: WallpaperScalingMode
    ) {
        wallpaperEngine
            .setScalingMode(mode)
    }

    // MARK: - Debug

    func runLifecycleStressTest() {
        Logger.engine.info(
            "Starting 20-cycle lifecycle stress test"
        )

        wallpaperEngine.stop()

        for iteration in 1...20 {
            Logger.engine.debug(
                "Lifecycle test iteration \(iteration)"
            )

            guard
                wallpaperEngine.videoURL
                    != nil
            else {
                Logger.engine.warning(
                    "Lifecycle test requires a selected wallpaper"
                )
                return
            }

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
