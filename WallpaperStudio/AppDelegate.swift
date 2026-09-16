import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: WallpaperWindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = WallpaperWindowManager()
    }
}
