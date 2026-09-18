import Cocoa
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var wallpaperWindowManager: WallpaperWindowManager?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Application finished launching"
        )

        wallpaperWindowManager = WallpaperWindowManager()
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        Logger.app.info(
            "Wallpaper Studio is terminating"
        )
    }

    func setScalingMode(_ mode: WallpaperScalingMode) {
        wallpaperWindowManager?.setScalingMode(mode)
    }
}
