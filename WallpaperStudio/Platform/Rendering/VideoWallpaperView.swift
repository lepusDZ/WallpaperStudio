import AVFoundation
import Cocoa
import OSLog

@MainActor
final class VideoWallpaperView: NSView {

    private let renderer: VideoWallpaperRenderer

    /// Normal initializer used by Wallpaper Studio.
    convenience init(
        frame frameRect: NSRect,
        sourceURL: URL
    ) throws {
        let renderer = try VideoWallpaperRenderer(
            sourceURL: sourceURL
        )

        self.init(
            frame: frameRect,
            renderer: renderer
        )

        renderer.play()
    }

    /// Separate initializer lets tests provide their own renderer.
    init(
        frame frameRect: NSRect,
        renderer: VideoWallpaperRenderer
    ) {
        self.renderer = renderer

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

    /// NSView calls this whenever the view's size/layout changes.
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

        renderer.playerLayer.frame = bounds
        renderer.playerLayer.videoGravity = .resizeAspectFill

        layer?.addSublayer(renderer.playerLayer)
    }
}
