import AVFoundation
import Cocoa
import Testing

@testable import WallpaperStudio

@MainActor
struct WallpaperStudioTests {

    // MARK: - Engine

    @Test
    func engineStartsStoppedWithoutVideo() {
        let engine =
            WallpaperEngine()

        #expect(
            engine.state == .stopped
        )

        #expect(
            engine.videoURL == nil
        )
    }

    @Test
    func engineCannotStartWithoutVideo() {
        let engine =
            WallpaperEngine()

        #expect(
            engine.start() == false
        )

        #expect(
            engine.state == .stopped
        )
    }

    // MARK: - Renderer

    @Test
    func rendererRejectsMissingVideoFile() {
        let missingURL =
            URL(
                fileURLWithPath:
                    "/tmp/wallpaper-studio-missing-video.mp4"
            )

        #expect(
            throws:
                VideoWallpaperRendererError.self
        ) {
            try VideoWallpaperRenderer(
                sourceURL:
                    missingURL
            )
        }
    }

    @Test
    func rendererStartsMuted() {
        let renderer =
            makeTestRenderer()

        #expect(
            renderer.isMuted
        )
    }

    @Test
    func rendererCreatesPlayerLayer() {
        let renderer =
            makeTestRenderer()

        #expect(
            renderer.playerLayer
                .player != nil
        )
    }

    @Test
    func rendererStopDisconnectsPlayer() {
        let renderer =
            makeTestRenderer()

        renderer.stop()

        #expect(
            renderer.playerLayer
                .player == nil
        )
    }

    @Test
    func rendererStopIsRepeatable() {
        let renderer =
            makeTestRenderer()

        renderer.stop()
        renderer.stop()
        renderer.stop()

        #expect(
            renderer.playerLayer
                .player == nil
        )
    }

    // MARK: - Scaling

    @Test
    func fillMapsToAspectFill() {
        #expect(
            WallpaperScalingMode
                .fill
                .avVideoGravity
                == .resizeAspectFill
        )
    }

    @Test
    func fitMapsToAspectFit() {
        #expect(
            WallpaperScalingMode
                .fit
                .avVideoGravity
                == .resizeAspect
        )
    }

    @Test
    func stretchMapsToResize() {
        #expect(
            WallpaperScalingMode
                .stretch
                .avVideoGravity
                == .resize
        )
    }

    @Test
    func changingScalingModeUpdatesLayer() {
        let renderer =
            makeTestRenderer()

        let view =
            VideoWallpaperView(
                frame:
                    testFrame,
                renderer:
                    renderer
            )

        view.scalingMode =
            .stretch

        #expect(
            renderer.playerLayer
                .videoGravity
                == .resize
        )
    }

    // MARK: - View

    @Test
    func videoViewAttachesPlayerLayer() {
        let renderer =
            makeTestRenderer()

        let view =
            VideoWallpaperView(
                frame:
                    testFrame,
                renderer:
                    renderer
            )

        let containsPlayerLayer =
            view.layer?
                .sublayers?
                .contains {
                    $0 ===
                        renderer
                            .playerLayer
                }
            ?? false

        #expect(
            containsPlayerLayer
        )
    }

    @Test
    func videoLayerMatchesViewBounds() {
        let renderer =
            makeTestRenderer()

        let view =
            VideoWallpaperView(
                frame:
                    testFrame,
                renderer:
                    renderer
            )

        view.layout()

        #expect(
            renderer.playerLayer
                .frame
                == view.bounds
        )
    }

    @Test
    func videoLayerResizesWithView() {
        let renderer =
            makeTestRenderer()

        let view =
            VideoWallpaperView(
                frame:
                    testFrame,
                renderer:
                    renderer
            )

        view.frame =
            NSRect(
                x: 0,
                y: 0,
                width: 2560,
                height: 1440
            )

        view.layout()

        #expect(
            renderer.playerLayer
                .frame
                == view.bounds
        )
    }

    // MARK: - Helpers

    private var testFrame: NSRect {
        NSRect(
            x: 0,
            y: 0,
            width: 1920,
            height: 1080
        )
    }

    private func makeTestRenderer()
        -> VideoWallpaperRenderer {

        let asset =
            AVMutableComposition()

        let playerItem =
            AVPlayerItem(
                asset: asset
            )

        return VideoWallpaperRenderer(
            playerItem:
                playerItem,
            sourceName:
                "test-video"
        )
    }
}
