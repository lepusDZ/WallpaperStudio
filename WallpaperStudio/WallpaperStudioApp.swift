import SwiftUI
import OSLog

@main
struct WallpaperStudioApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    init() {
        Logger.app.info("Wallpaper Studio started")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 820, height: 520)
    }
}
