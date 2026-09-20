import AVFoundation
import Cocoa
import Testing

@testable import WallpaperStudio

@MainActor
struct WallpaperStudioTests {

    // MARK: - Wallpaper Engine

    @Test
    func engineStartsStoppedWithoutVideo() {
        let engine = WallpaperEngine()

        #expect(engine.state == .stopped)
        #expect(engine.videoURL == nil)
    }

    @Test
    func engineCannotStartWithoutVideo() {
        let engine = WallpaperEngine()

        let started = engine.start()

        #expect(started == false)
        #expect(engine.state == .stopped)
    }

    @Test
    func engineCanStoreSelectedVideoURLWhileStopped() {
        let engine = WallpaperEngine()

        let url = URL(
            fileURLWithPath: "/tmp/test-wallpaper.mp4"
        )

        let accepted = engine.setVideoURL(url)

        #expect(accepted)
        #expect(engine.videoURL == url)
    }

    @Test
    func engineScalingModeCanChangeWhileStopped() {
        let engine = WallpaperEngine()

        engine.setScalingMode(.fit)

        #expect(engine.scalingMode == .fit)
    }

    // MARK: - Renderer

    @Test
    func rendererRejectsMissingVideoFile() {
        let missingURL = URL(
            fileURLWithPath:
                "/tmp/wallpaper-studio-file-that-does-not-exist.mp4"
        )

        #expect(
            throws: VideoWallpaperRendererError.self
        ) {
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

        #expect(
            renderer.playerLayer.player != nil
        )
    }

    @Test
    func rendererStopDisconnectsPlayer() {
        let renderer = makeTestRenderer()

        renderer.stop()

        #expect(
            renderer.playerLayer.player == nil
        )
    }

    @Test
    func rendererStopCanBeCalledRepeatedly() {
        let renderer = makeTestRenderer()

        renderer.stop()
        renderer.stop()
        renderer.stop()

        #expect(
            renderer.playerLayer.player == nil
        )
    }

    // MARK: - Scaling

    @Test
    func fillMapsToAspectFill() {
        #expect(
            WallpaperScalingMode.fill.avVideoGravity
                == .resizeAspectFill
        )
    }

    @Test
    func fitMapsToAspectFit() {
        #expect(
            WallpaperScalingMode.fit.avVideoGravity
                == .resizeAspect
        )
    }

    @Test
    func stretchMapsToResize() {
        #expect(
            WallpaperScalingMode.stretch.avVideoGravity
                == .resize
        )
    }

    @Test
    func videoViewUsesInitialScalingMode() {
        let renderer = makeTestRenderer()

        _ = VideoWallpaperView(
            frame: testFrame,
            renderer: renderer,
            scalingMode: .fit
        )

        #expect(
            renderer.playerLayer.videoGravity
                == .resizeAspect
        )
    }

    @Test
    func changingScalingModeUpdatesPlayerLayer() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: testFrame,
            renderer: renderer
        )

        view.scalingMode = .stretch

        #expect(
            renderer.playerLayer.videoGravity
                == .resize
        )
    }

    // MARK: - Video View

    @Test
    func videoViewAttachesPlayerLayer() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: testFrame,
            renderer: renderer
        )

        let containsPlayerLayer =
            view.layer?
                .sublayers?
                .contains {
                    $0 === renderer.playerLayer
                }
            ?? false

        #expect(containsPlayerLayer)
    }

    @Test
    func videoLayerMatchesViewBounds() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: testFrame,
            renderer: renderer
        )

        view.layout()

        #expect(
            renderer.playerLayer.frame
                == view.bounds
        )
    }

    @Test
    func videoLayerResizesWithView() {
        let renderer = makeTestRenderer()

        let view = VideoWallpaperView(
            frame: testFrame,
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
            renderer.playerLayer.frame
                == view.bounds
        )
    }

    // MARK: - Display Assignment

    @Test
    func displayMatchingUsesIDInsteadOfArrayIndex() {
        let macBookBefore = makeDisplay(
            id: "macbook",
            name: "Built-in Retina Display",
            x: 0
        )

        let lgBefore = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470
        )

        // Same physical displays, but NSScreen-style array order changed.
        let currentDisplays = [
            lgBefore,
            macBookBefore
        ]

        let matches = DisplayAssignmentMatcher.match(
            previous: [
                macBookBefore,
                lgBefore
            ],
            current: currentDisplays
        )

        #expect(matches.count == 2)

        let matchedIDs = Set(
            matches.map {
                $0.current.id
            }
        )

        #expect(
            matchedIDs
                == Set([
                    macBookBefore.id,
                    lgBefore.id
                ])
        )

        for match in matches {
            #expect(
                match.previous.id
                    == match.current.id
            )
        }
    }

    @Test
    func reorderingDisplaysDoesNotCountAsTopologyChange() {
        let macBook = makeDisplay(
            id: "macbook",
            name: "Built-in Retina Display",
            x: 0
        )

        let lg = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                macBook,
                lg
            ],
            current: [
                lg,
                macBook
            ]
        )

        #expect(change.added.isEmpty)
        #expect(change.removed.isEmpty)
        #expect(change.updated.isEmpty)
        #expect(change.hasChanges == false)
    }

    @Test
    func topologyDetectsNewDisplay() {
        let macBook = makeDisplay(
            id: "macbook",
            name: "Built-in Retina Display",
            x: 0
        )

        let lg = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                macBook
            ],
            current: [
                macBook,
                lg
            ]
        )

        #expect(
            change.added.map(\.id)
                == [lg.id]
        )

        #expect(change.removed.isEmpty)
    }

    @Test
    func topologyDetectsRemovedDisplay() {
        let macBook = makeDisplay(
            id: "macbook",
            name: "Built-in Retina Display",
            x: 0
        )

        let lg = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                macBook,
                lg
            ],
            current: [
                macBook
            ]
        )

        #expect(change.added.isEmpty)

        #expect(
            change.removed.map(\.id)
                == [lg.id]
        )
    }

    @Test
    func replacingDisplayProducesAddedAndRemovedIDs() {
        let macBook = makeDisplay(
            id: "macbook",
            name: "Built-in Retina Display",
            x: 0
        )

        let oldLG = makeDisplay(
            id: "old-lg",
            name: "Old LG",
            x: 1470
        )

        let newLG = makeDisplay(
            id: "new-lg",
            name: "New LG",
            x: 1470
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                macBook,
                oldLG
            ],
            current: [
                newLG,
                macBook
            ]
        )

        #expect(
            change.added.map(\.id)
                == [newLG.id]
        )

        #expect(
            change.removed.map(\.id)
                == [oldLG.id]
        )

        #expect(change.updated.isEmpty)
    }

    @Test
    func topologyDetectsFrameChangeForSameDisplay() {
        let before = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470,
            width: 2560,
            height: 1440
        )

        let after = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: -3008,
            width: 3008,
            height: 1692
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                before
            ],
            current: [
                after
            ]
        )

        #expect(change.added.isEmpty)
        #expect(change.removed.isEmpty)
        #expect(change.updated.count == 1)

        let update = change.updated[0]

        #expect(
            update.previous.id
                == update.current.id
        )

        #expect(
            update.current.logicalFrame
                == after.logicalFrame
        )
    }

    @Test
    func topologyDetectsScaleFactorChangeForSameDisplay() {
        let before = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470,
            backingScaleFactor: 1
        )

        let after = makeDisplay(
            id: "lg-ultrafine",
            name: "LG UltraFine",
            x: 1470,
            backingScaleFactor: 2
        )

        let change = DisplayTopologyChange.compare(
            previous: [
                before
            ],
            current: [
                after
            ]
        )

        #expect(change.added.isEmpty)
        #expect(change.removed.isEmpty)
        #expect(change.updated.count == 1)

        #expect(
            change.updated[0]
                .current
                .backingScaleFactor == 2
        )
    }

    @Test
    func displayIDsHaveDeterministicOrdering() {
        let first = DisplayID(
            rawValue: "display-a"
        )

        let second = DisplayID(
            rawValue: "display-b"
        )

        #expect(first < second)
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

        let asset = AVMutableComposition()

        let playerItem = AVPlayerItem(
            asset: asset
        )

        return VideoWallpaperRenderer(
            playerItem: playerItem,
            sourceName: "test-video"
        )
    }

    private func makeDisplay(
        id: String,
        name: String,
        x: CGFloat,
        y: CGFloat = 0,
        width: CGFloat = 1470,
        height: CGFloat = 956,
        backingScaleFactor: CGFloat = 2
    ) -> DisplayDescriptor {

        DisplayDescriptor(
            id: DisplayID(
                rawValue: id
            ),
            name: name,
            logicalFrame: CGRect(
                x: x,
                y: y,
                width: width,
                height: height
            ),
            backingScaleFactor:
                backingScaleFactor,
            pixelWidth:
                Int(
                    width
                    * backingScaleFactor
                ),
            pixelHeight:
                Int(
                    height
                    * backingScaleFactor
                ),
            currentRefreshRate: 60,
            minimumRefreshRate: 60,
            maximumRefreshRate: 60,
            maximumFramesPerSecond: 60
        )
    }
}
