import SwiftUI
import OSLog

struct ContentView: View {

    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onLifecycleStressTest: () -> Void

    let onScalingModeChange:
        (WallpaperScalingMode) -> Void

    @State
    private var scalingMode:
        WallpaperScalingMode = .fill

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(
                systemName:
                    "photo.on.rectangle.angled"
            )
            .font(.system(size: 52))
            .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Wallpaper Studio")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text(
                    "Native dynamic wallpapers for macOS."
                )
                .foregroundStyle(.secondary)
            }

            scalingControls

            #if DEBUG
            lifecycleDebugControls
            #endif

            Spacer()

            Text("Under active development")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(40)
        .onAppear {
            Logger.app.info("ContentView appeared")
        }
    }

    // MARK: - Scaling

    private var scalingControls: some View {
        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Scaling Mode")
                    .font(.headline)

                Picker(
                    "Scaling Mode",
                    selection: $scalingMode
                ) {
                    ForEach(
                        WallpaperScalingMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
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

    // MARK: - Debug

    #if DEBUG
    private var lifecycleDebugControls:
        some View {

        GroupBox {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Lifecycle Debug")
                    .font(.headline)

                HStack {
                    lifecycleButton(
                        "Start",
                        systemImage: "play.fill",
                        action: onStart
                    )

                    lifecycleButton(
                        "Pause",
                        systemImage: "pause.fill",
                        action: onPause
                    )

                    lifecycleButton(
                        "Resume",
                        systemImage:
                            "play.circle.fill",
                        action: onResume
                    )

                    lifecycleButton(
                        "Stop",
                        systemImage: "stop.fill",
                        action: onStop
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

                Text(
                    "Controls intentionally remain enabled so repeated lifecycle calls can be tested."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(4)
        }
        .frame(width: 420)
    }

    private func lifecycleButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            Label(
                title,
                systemImage: systemImage
            )
        }
    }
    #endif
}

#Preview {
    ContentView(
        onStart: {},
        onPause: {},
        onResume: {},
        onStop: {},
        onLifecycleStressTest: {},
        onScalingModeChange: { _ in }
    )
    .frame(
        width: 820,
        height: 520
    )
}
