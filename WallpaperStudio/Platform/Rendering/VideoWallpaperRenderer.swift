import AVFoundation
import OSLog

@MainActor
final class VideoWallpaperRenderer {

    let playerLayer: AVPlayerLayer

    private let player: AVQueuePlayer

    private let looper: AVPlayerLooper

    private var statusObservation: NSKeyValueObservation?

    private let sourceName: String

    var isMuted: Bool {
        player.isMuted
    }

    /// Creates a renderer for a local video file.
    convenience init(sourceURL: URL) throws {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            Logger.rendering.error(
                "Video file not found: \(sourceURL.path, privacy: .public)"
            )

            throw VideoWallpaperRendererError.fileNotFound(sourceURL)
        }

        Logger.rendering.info(
            "Loading video: \(sourceURL.lastPathComponent, privacy: .public)"
        )

        let playerItem = AVPlayerItem(url: sourceURL)

        self.init(
            playerItem: playerItem,
            sourceName: sourceURL.lastPathComponent
        )
    }

    /// Allows tests to provide an AVPlayerItem without depending on
    /// a developer-specific video file.
    init(
        playerItem: AVPlayerItem,
        sourceName: String
    ) {
        let player = AVQueuePlayer()
        player.isMuted = true

        self.player = player
        self.playerLayer = AVPlayerLayer(player: player)

        self.looper = AVPlayerLooper(
            player: player,
            templateItem: playerItem
        )

        self.sourceName = sourceName

        observePlayerStatus()

        Logger.rendering.info(
            "Video source configured: \(sourceName, privacy: .public)"
        )
    }

    func play() {
        player.play()

        Logger.rendering.info(
            "Playing video: \(self.sourceName, privacy: .public)"
        )
    }

    func pause() {
        player.pause()

        Logger.rendering.info(
            "Paused video: \(self.sourceName, privacy: .public)"
        )
    }

    // MARK: - Player State

    private func observePlayerStatus() {
        let observedSourceName = sourceName

        statusObservation = player.observe(
            \.status,
            options: [.initial, .new]
        ) { player, _ in

            switch player.status {
            case .unknown:
                Logger.rendering.debug(
                    "Waiting for video: \(observedSourceName, privacy: .public)"
                )

            case .readyToPlay:
                Logger.rendering.info(
                    "Video ready to play: \(observedSourceName, privacy: .public)"
                )

            case .failed:
                let errorMessage =
                    player.error?.localizedDescription
                    ?? "Unknown playback error"

                Logger.rendering.error(
                    """
                    Video playback failed for \
                    \(observedSourceName, privacy: .public): \
                    \(errorMessage, privacy: .public)
                    """
                )

            @unknown default:
                Logger.rendering.warning(
                    "Unknown player status for \(observedSourceName, privacy: .public)"
                )
            }
        }
    }
}

enum VideoWallpaperRendererError: LocalizedError {
    case fileNotFound(URL)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Video file was not found at \(url.path)"
        }
    }
}
