import AppKit
import SwiftUI

struct ContentView: View {

    @ObservedObject
    var benchmark:
        DebugPerformanceBenchmark

    let onChooseVideo: () -> URL?

    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void

    let onLifecycleStressTest:
        () -> Void

    let onScalingModeChange:
        (WallpaperScalingMode) -> Void

    @State
    private var selectedVideoName =
        "No video selected"

    @State
    private var scalingMode:
        WallpaperScalingMode = .fill

    var body: some View {
        VStack(spacing: 24) {
            header

            wallpaperControls

            scalingControls

            #if DEBUG
            lifecycleDebugControls
            performanceDebugControls
            #endif

            Spacer()

            Text(
                "Under active development"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(40)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(
                systemName:
                    "photo.on.rectangle.angled"
            )
            .font(.system(size: 48))
            .foregroundStyle(.secondary)

            Text("Wallpaper Studio")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(
                "Native dynamic wallpapers for macOS."
            )
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Wallpaper

    private var wallpaperControls:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Wallpaper")
                    .font(.headline)

                HStack {
                    Image(
                        systemName:
                            "film"
                    )

                    Text(
                        selectedVideoName
                    )
                    .lineLimit(1)
                    .truncationMode(
                        .middle
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Spacer()

                    Button {
                        guard
                            let url =
                                onChooseVideo()
                        else {
                            return
                        }

                        selectedVideoName =
                            url.lastPathComponent
                    } label: {
                        Label(
                            "Choose Video",
                            systemImage:
                                "folder"
                        )
                    }
                    .disabled(
                        benchmark.isRunning
                    )
                }
            }
            .padding(4)
        }
        .frame(width: 460)
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
                        "Pause",
                        systemImage:
                            "pause.fill",
                        action:
                            onPause
                    )

                    lifecycleButton(
                        "Resume",
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
        .frame(width: 460)
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

                    Text(
                        "Full suite benchmarks all four videos through plain AVFoundation and Wallpaper Studio for 10 minutes each."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
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
        .frame(width: 520)
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
