import SwiftUI
import OSLog

@main
struct WallpaperStudioApp: App {
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
