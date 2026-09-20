//
//  AVFoundationReferencePlayer.swift
//  WallpaperStudio
//
//  Created by Dmytro Zaichenko on 2026-09-19.
//


import AVFoundation
import Cocoa

@MainActor
final class AVFoundationReferencePlayer {

    private let player: AVQueuePlayer
    private let looper: AVPlayerLooper
    private let playerLayer: AVPlayerLayer

    private let window: NSWindow

    private var isStopped = false

    init(
        sourceURL: URL,
        screen: NSScreen
    ) {
        let player = AVQueuePlayer()
        player.isMuted = true

        let playerItem = AVPlayerItem(
            url: sourceURL
        )

        self.player = player

        looper = AVPlayerLooper(
            player: player,
            templateItem: playerItem
        )

        playerLayer = AVPlayerLayer(
            player: player
        )

        playerLayer.videoGravity =
            .resizeAspectFill

        let contentFrame = NSRect(
            origin: .zero,
            size: screen.frame.size
        )

        let videoView = ReferenceVideoView(
            frame: contentFrame,
            playerLayer: playerLayer
        )

        window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.contentView = videoView
    }

    func start() {
        guard !isStopped else {
            return
        }

        window.orderFront(nil)
        player.play()
    }

    func stop() {
        guard !isStopped else {
            return
        }

        isStopped = true

        player.pause()
        looper.disableLooping()

        playerLayer.player = nil

        window.contentView = nil
        window.close()
    }
}

@MainActor
private final class ReferenceVideoView: NSView {

    private let playerLayer: AVPlayerLayer

    init(
        frame frameRect: NSRect,
        playerLayer: AVPlayerLayer
    ) {
        self.playerLayer = playerLayer

        super.init(frame: frameRect)

        wantsLayer = true

        layer?.backgroundColor =
            NSColor.black.cgColor

        layer?.masksToBounds = true

        playerLayer.frame = bounds

        layer?.addSublayer(
            playerLayer
        )
    }

    required init?(coder: NSCoder) {
        fatalError(
            "ReferenceVideoView does not support NSCoder"
        )
    }

    override func layout() {
        super.layout()

        playerLayer.frame = bounds
    }
}