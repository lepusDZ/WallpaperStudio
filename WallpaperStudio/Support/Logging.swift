import OSLog

extension Logger {

    private static let subsystem =
        "io.github.lepusDZ.WallpaperStudio"

    static let app = Logger(
        subsystem: subsystem,
        category: "App"
    )

    static let engine = Logger(
        subsystem: subsystem,
        category: "Engine"
    )

    static let display = Logger(
        subsystem: subsystem,
        category: "Display"
    )

    static let rendering = Logger(
        subsystem: subsystem,
        category: "Rendering"
    )
}
