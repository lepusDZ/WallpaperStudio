import AppKit
import SwiftUI

struct ContentView: View {

    @ObservedObject
    var engine: WallpaperEngine

    @ObservedObject
    var benchmark: DebugPerformanceBenchmark

    let onChooseWallpaper:
        (DisplayID) -> Void

    let onClearWallpaper:
        (DisplayID) -> Void

    let onPauseDisplay:
        (DisplayID) -> Void

    let onResumeDisplay:
        (DisplayID) -> Void

    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void

    let onLifecycleStressTest:
        () -> Void

    let onScalingModeChange:
        (WallpaperScalingMode) -> Void

    @State
    private var scalingMode:
        WallpaperScalingMode = .fill

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                displayAssignments

                scalingControls

                #if DEBUG
                lifecycleDebugControls
                performanceDebugControls
                #endif

                Text(
                    "Under active development"
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(40)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(
                systemName:
                    "photo.on.rectangle.angled"
            )
            .font(
                .system(size: 48)
            )
            .foregroundStyle(
                .secondary
            )

            Text("Wallpaper Studio")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(
                "Native dynamic wallpapers for macOS."
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - Displays

    private var displayAssignments:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                Text("Displays")
                    .font(.headline)

                if engine.displays.isEmpty {
                    Text(
                        "No displays detected."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                } else {
                    ForEach(
                        engine.displays
                    ) { display in

                        displayRow(
                            display
                        )
                    }
                }
            }
            .padding(4)
        }
        .frame(width: 560)
    }

    private func displayRow(
        _ display: DisplayDescriptor
    ) -> some View {

        let wallpaper =
            engine.wallpaperAssignments[
                display.id
            ]

        let isPaused =
            engine.pausedDisplayIDs
                .contains(
                    display.id
                )

        return VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(
                        display.name
                    )
                    .fontWeight(
                        .semibold
                    )

                    Text(
                        display.isBuiltIn
                        ? "Built-in display"
                        : "External display"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                if isPaused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }

            HStack {
                Image(
                    systemName:
                        "film"
                )
                .foregroundStyle(
                    .secondary
                )

                Text(
                    wallpaper?
                        .displayName
                    ?? "No wallpaper assigned"
                )
                .lineLimit(1)
                .truncationMode(
                    .middle
                )
                .foregroundStyle(
                    wallpaper == nil
                    ? .secondary
                    : .primary
                )

                Spacer()
            }

            HStack {
                Button {
                    onChooseWallpaper(
                        display.id
                    )
                } label: {
                    Label(
                        wallpaper == nil
                        ? "Choose Video"
                        : "Change Video",
                        systemImage:
                            "folder"
                    )
                }

                if wallpaper != nil {
                    Button(
                        role: .destructive
                    ) {
                        onClearWallpaper(
                            display.id
                        )
                    } label: {
                        Label(
                            "Clear",
                            systemImage:
                                "xmark"
                        )
                    }

                    Spacer()

                    if engine.state
                        != .stopped {

                        if isPaused {
                            Button {
                                onResumeDisplay(
                                    display.id
                                )
                            } label: {
                                Label(
                                    "Resume",
                                    systemImage:
                                        "play.fill"
                                )
                            }
                        } else {
                            Button {
                                onPauseDisplay(
                                    display.id
                                )
                            } label: {
                                Label(
                                    "Pause",
                                    systemImage:
                                        "pause.fill"
                                )
                            }
                        }
                    }
                }
            }

            if display.id
                != engine.displays
                    .last?.id {

                Divider()
                    .padding(.top, 4)
            }
        }
        .disabled(
            benchmark.isRunning
        )
    }

    // MARK: - Scaling

    private var scalingControls:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Scaling Mode")
                    .font(.headline)

                Picker(
                    "Scaling Mode",
                    selection:
                        $scalingMode
                ) {
                    ForEach(
                        WallpaperScalingMode
                            .allCases,
                        id: \.self
                    ) { mode in

                        Text(
                            mode.displayName
                        )
                        .tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(
                    .segmented
                )
                .controlSize(.large)
                .onChange(
                    of: scalingMode
                ) { _, newMode in

                    onScalingModeChange(
                        newMode
                    )
                }
            }
            .padding(4)
        }
        .frame(width: 340)
    }

    // MARK: - Debug Lifecycle

    #if DEBUG

    private var lifecycleDebugControls:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text(
                    "Lifecycle Debug"
                )
                .font(.headline)

                HStack {
                    lifecycleButton(
                        "Start",
                        systemImage:
                            "play.fill",
                        action:
                            onStart
                    )

                    lifecycleButton(
                        "Pause All",
                        systemImage:
                            "pause.fill",
                        action:
                            onPause
                    )

                    lifecycleButton(
                        "Resume All",
                        systemImage:
                            "play.circle.fill",
                        action:
                            onResume
                    )

                    lifecycleButton(
                        "Stop",
                        systemImage:
                            "stop.fill",
                        action:
                            onStop
                    )
                }

                Button {
                    onLifecycleStressTest()
                } label: {
                    Label(
                        "Run 20x Lifecycle Test",
                        systemImage:
                            "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }
            }
            .padding(4)
        }
        .frame(width: 560)
        .disabled(
            benchmark.isRunning
        )
    }

    // MARK: - Debug Performance

    private var performanceDebugControls:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text(
                    "Performance Benchmark"
                )
                .font(.headline)

                Text(
                    "~/Library/wallpapers"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                if benchmark.isRunning {
                    ProgressView(
                        value:
                            benchmark.progress
                    )

                    Text(
                        benchmark.statusText
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    Button(
                        role: .destructive
                    ) {
                        benchmark.cancel()
                    } label: {
                        Label(
                            "Cancel Benchmark",
                            systemImage:
                                "xmark.circle"
                        )
                    }
                } else {
                    HStack {
                        Button {
                            benchmark
                                .runQuickSuite()
                        } label: {
                            Label(
                                "Quick 1-Min Suite",
                                systemImage:
                                    "hare"
                            )
                        }

                        Button {
                            benchmark
                                .runFullSuite()
                        } label: {
                            Label(
                                "Full Day 9 Suite",
                                systemImage:
                                    "gauge.with.dots.needle.67percent"
                            )
                        }
                    }
                }

                if let reportURL =
                    benchmark.lastReportURL {

                    Divider()

                    Button {
                        NSWorkspace.shared
                            .activateFileViewerSelecting(
                                [
                                    reportURL
                                ]
                            )
                    } label: {
                        Label(
                            "Show Last Report",
                            systemImage:
                                "doc.text.magnifyingglass"
                        )
                    }
                }
            }
            .padding(4)
        }
        .frame(width: 560)
    }

    private func lifecycleButton(
        _ title: String,
        systemImage: String,
        action:
            @escaping () -> Void
    ) -> some View {

        Button(
            action: action
        ) {
            Label(
                title,
                systemImage:
                    systemImage
            )
        }
    }

    #endif
}
