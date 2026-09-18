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

    /// Normal initializer used when displaying a video from disk.
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

    /// Allows tests to provide their own renderer.
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

    /// Keeps the AVPlayerLayer matched to the NSView when its size changes.
    override func layout() {
        super.layout()

        renderer.playerLayer.frame = bounds
    }

    func play() {
        renderer.play()
    }

    func pause() {
        renderer.pause()
    }

    // MARK: - Setup

    private func configurePlayerLayer() {
        wantsLayer = true

        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true

        renderer.playerLayer.frame = bounds

        applyScalingMode()

        layer?.addSublayer(renderer.playerLayer)
    }

    private func applyScalingMode() {
        renderer.playerLayer.videoGravity = scalingMode.avVideoGravity
    }
}
