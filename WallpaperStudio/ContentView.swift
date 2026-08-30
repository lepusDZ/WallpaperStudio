import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))

            Text("Wallpaper Studio")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Native dynamic wallpapers for macOS.")
                .foregroundStyle(.secondary)

            Text("Under active development")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    ContentView()
        .frame(width: 820, height: 520)
}
