import AVFoundation
import Cocoa
import Testing

@testable import WallpaperStudio

@MainActor
struct WallpaperStudioTests {

    @Test
    func rendererRejectsMissingVideoFile() {
        let missingURL = URL(
            fileURLWithPath:
                "/tmp/wallpaper-studio-file-that-does-not-exist.mp4"
        )

        #expect(throws: VideoWallpaperRendererError.self) {
            try VideoWallpaperRenderer(
                sourceURL: missingURL
            )
        }
    }

    @Test
    func rendererStartsMuted() {
        let renderer = makeTestRenderer()

        #expect(renderer.isMuted)
    }

    @Test
    func rendererCreatesPlayerLayer() {
        let renderer = makeTestRenderer()

        #expect(renderer.playerLayer.player != nil)
    }

    @Test
    func videoViewAttachesPlayerLayer() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 1920,
                height: 1080
            ),
            renderer: renderer
        )

        #expect(
            renderer.playerLayer.superlayer === view.layer
        )
    }

    @Test
    func videoLayerMatchesViewBounds() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 1920,
                height: 1080
            ),
            renderer: renderer
        )

        view.layout()

        #expect(
            renderer.playerLayer.frame == view.bounds
        )
    }

    @Test
    func videoLayerResizesWithView() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 1920,
                height: 1080
            ),
            renderer: renderer
        )

        view.frame = NSRect(
            x: 0,
            y: 0,
            width: 2560,
            height: 1440
        )

        view.layout()

        #expect(
            renderer.playerLayer.frame == view.bounds
        )
    }

    // MARK: - Helpers

    private func makeTestRenderer() -> VideoWallpaperRenderer {
        let asset = AVMutableComposition()
        let playerItem = AVPlayerItem(asset: asset)

        return VideoWallpaperRenderer(
            playerItem: playerItem,
            sourceName: "test-video"
        )
    }
}
