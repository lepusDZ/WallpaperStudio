import AVFoundation
import Cocoa
import OSLog

@MainActor
final class VideoWallpaperView: NSView {

    private let renderer: VideoWallpaperRenderer

    var scalingMode: WallpaperScalingMode {
        didSet {
            guard scalingMode != oldValue else {
                return
            }

            applyScalingMode()
        }
    }

    convenience init(
        frame frameRect: NSRect,
        sourceURL: URL,
        scalingMode: WallpaperScalingMode = .fill
    ) throws {
        let renderer = try VideoWallpaperRenderer(
            sourceURL: sourceURL
        )

        self.init(
            frame: frameRect,
            renderer: renderer,
            scalingMode: scalingMode
        )
    }

    init(
        frame frameRect: NSRect,
        renderer: VideoWallpaperRenderer,
        scalingMode: WallpaperScalingMode = .fill
    ) {
        self.renderer = renderer
        self.scalingMode = scalingMode

        super.init(frame: frameRect)

        configurePlayerLayer()

        Logger.rendering.debug(
            "VideoWallpaperView initialized"
        )
    }

    required init?(coder: NSCoder) {
        fatalError(
            "VideoWallpaperView does not support initialization from NSCoder"
        )
    }
    
    deinit {
        Logger.rendering.debug(
            "VideoWallpaperView released"
        )
    }

    override func layout() {
        super.layout()

        renderer.playerLayer.frame = bounds
    }

    // MARK: - Lifecycle

    func pause() {
        renderer.pause()
    }

    func resume() {
        renderer.play()
    }

    func stop() {
        renderer.stop()
    }

    // MARK: - Setup

    private func configurePlayerLayer() {
        wantsLayer = true

        layer?.backgroundColor =
            NSColor.black.cgColor

        layer?.masksToBounds = true

        renderer.playerLayer.frame = bounds

        applyScalingMode()

        layer?.addSublayer(
            renderer.playerLayer
        )
    }

    private func applyScalingMode() {
        renderer.playerLayer.videoGravity =
            scalingMode.avVideoGravity
    }
}
