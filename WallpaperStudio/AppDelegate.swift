import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: WallpaperWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = WallpaperWindowController()
    }
}
