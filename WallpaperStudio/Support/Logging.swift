import OSLog

extension Logger {
    private static let subsystem = "io.github.lepusDZ.WallpaperStudio"

    static let app = Logger(
        subsystem: subsystem,
        category: "app"
    )

    static let engine = Logger(
        subsystem: subsystem,
        category: "engine"
    )

    static let display = Logger(
        subsystem: subsystem,
        category: "display"
    )

    static let rendering = Logger(
        subsystem: subsystem,
        category: "rendering"
    )
}
