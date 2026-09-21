import Foundation

struct Wallpaper: Identifiable, Hashable, Sendable {

    let sourceURL: URL

    var id: URL {
        sourceURL.standardizedFileURL
    }

    var displayName: String {
        sourceURL.lastPathComponent
    }
}
