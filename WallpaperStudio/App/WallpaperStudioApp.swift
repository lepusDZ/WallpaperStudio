import OSLog
import SwiftUI

@main
struct WallpaperStudioApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    init() {
        Logger.app.debug(
            "WallpaperStudioApp initialized"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView { scalingMode in
                appDelegate.setScalingMode(scalingMode)
            }
        }
        .defaultSize(
            width: 820,
            height: 520
        )
    }
}
