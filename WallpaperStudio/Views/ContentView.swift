import SwiftUI

struct ContentView: View {

    let onScalingModeChange: (WallpaperScalingMode) -> Void

    @State
    private var scalingMode: WallpaperScalingMode = .fill

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Wallpaper Studio")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Native dynamic wallpapers for macOS.")
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
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
                    .onChange(of: scalingMode) { _, newMode in
                        onScalingModeChange(newMode)
                    }
                }
                .padding(4)
            }
            .frame(width: 340)

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
    }
}

#Preview {
    ContentView { _ in }
        .frame(
            width: 820,
            height: 520
        )
}
