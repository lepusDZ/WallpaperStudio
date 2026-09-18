import Foundation

enum DevelopmentAssets {

    // Temporary local video used while the wallpaper engine is in development.
    // The video itself is not stored in the project or app bundle.
    static let videoURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Downloads")
        .appending(path: "valley-misty-moewalls-com.mp4")
}
