import OSLog
import SwiftUI

@main
struct WallpaperStudioApp: App {

    @NSApplicationDelegateAdaptor(
        AppDelegate.self
    )
    private var appDelegate

    init() {
        Logger.app.debug(
            "WallpaperStudioApp initialized"
        )
    }

    var body: some Scene {
        Window(
            "Wallpaper Studio",
            id: "main-control"
        ) {
            ContentView(
                benchmark:
                    appDelegate
                        .performanceBenchmark,
                onChooseVideo: {
                    appDelegate
                        .chooseWallpaper()
                },
                onStart: {
                    appDelegate
                        .startWallpaper()
                },
                onPause: {
                    appDelegate
                        .pauseWallpaper()
                },
                onResume: {
                    appDelegate
                        .resumeWallpaper()
                },
                onStop: {
                    appDelegate
                        .stopWallpaper()
                },
                onLifecycleStressTest: {
                    appDelegate
                        .runLifecycleStressTest()
                },
                onScalingModeChange: {
                    mode in

                    appDelegate
                        .setScalingMode(
                            mode
                        )
                }
            )
            .onAppear {
                Logger.app.info(
                    "Main control window appeared"
                )
            }
        }
        .defaultSize(
            width: 820,
            height: 760
        )
        .restorationBehavior(
            .disabled
        )
        .defaultLaunchBehavior(
            .presented
        )
    }
}
