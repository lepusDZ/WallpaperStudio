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
                engine:
                    appDelegate
                        .wallpaperEngine,
                benchmark:
                    appDelegate
                        .performanceBenchmark,
                onChooseWallpaper: {
                    displayID in

                    appDelegate
                        .chooseWallpaper(
                            for: displayID
                        )
                },
                onClearWallpaper: {
                    displayID in

                    appDelegate
                        .clearWallpaper(
                            for: displayID
                        )
                },
                onPauseDisplay: {
                    displayID in

                    appDelegate
                        .pauseWallpaper(
                            on: displayID
                        )
                },
                onResumeDisplay: {
                    displayID in

                    appDelegate
                        .resumeWallpaper(
                            on: displayID
                        )
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
            height: 820
        )
        .restorationBehavior(
            .disabled
        )
        .defaultLaunchBehavior(
            .presented
        )
    }
}
