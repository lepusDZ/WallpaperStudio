import Cocoa
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let wallpaperEngine =
        WallpaperEngine()

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Application finished launching"
        )
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Wallpaper Studio is terminating"
        )

        wallpaperEngine.stop()
    }

    // MARK: - Wallpaper Controls

    func startWallpaper() {
        wallpaperEngine.start()
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
        wallpaperEngine.setScalingMode(mode)
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

            wallpaperEngine.start()
            wallpaperEngine.pause()
            wallpaperEngine.resume()
            wallpaperEngine.stop()
        }

        Logger.engine.info(
            "20-cycle lifecycle stress test completed"
        )
    }
}
