# Wallpaper Studio

Wallpaper Studio is an open-source native dynamic wallpaper engine for macOS, built with Swift and Apple's native frameworks.

The project aims to become a high-performance, macOS-native alternative to traditional live-wallpaper utilities, with animated wallpapers, multi-display support, performance-aware playback, and eventually extensible wallpaper formats and community content.

> **Status:** Wallpaper Studio is under active development. The repository currently contains only the native macOS application foundation; live wallpaper functionality has not been implemented yet.

## Goals

- **Native first** — Swift, SwiftUI, AppKit, AVFoundation, and Metal.
- **Performance first** — minimize CPU, GPU, memory, and battery usage when wallpapers are not visible.
- **Local first** — local wallpapers should work without an account, backend, or Steam.
- **Extensible** — additional wallpaper types should be added without redesigning the application.
- **Open source** — architecture, implementation decisions, and performance work remain visible and documented.

## Planned technologies

- **Swift / SwiftUI** — application and user interface
- **AppKit** — desktop-level windows and display integration
- **AVFoundation** — video wallpaper playback
- **Metal** — GPU-rendered wallpapers and visual effects
- **ServiceManagement** — launch-at-login support
- **Steamworks** — optional Steam Workshop integration in a future Steam distribution

## Initial direction

The first engineering milestone is a proof of concept that hosts a rendering surface in a desktop-level AppKit window while leaving normal macOS desktop interaction unaffected.

After that, development will progress toward:

- looping local video wallpapers;
- multiple-display support;
- per-display wallpaper selection;
- sleep, fullscreen, and power-aware playback;
- local wallpaper storage and thumbnails;
- menu bar controls and launch at login;
- Metal-rendered scenes and additional wallpaper formats;
- optional Steam Workshop integration.

## Roadmap

### v0.1 — Desktop proof of concept

- Desktop-level borderless AppKit window
- Mouse-event passthrough
- Single-display rendering
- Looping local video with AVFoundation
- Initial Spaces and fullscreen behavior testing

### v0.2 — Wallpaper engine

- Display discovery
- One wallpaper surface per display
- Video scaling modes
- Local video import
- Wallpaper persistence
- Restore selected wallpapers after relaunch

### v0.3 — System integration

- Sleep/wake handling
- Display connect/disconnect handling
- Fullscreen-aware playback
- Battery/performance policies
- Menu bar controls
- Launch at login
- Instruments profiling

### v0.4 — Local library

- Wallpaper library
- Thumbnails
- Metadata
- Favorites
- Search and filtering
- Per-display assignments

### v0.5 — Extensible rendering

- Shared renderer lifecycle
- Video renderer
- Metal renderer
- Configurable frame-rate policies

### Later

- Signed and notarized releases
- Optional Steam Workshop integration
- Wallpaper publishing tools
- Web wallpapers
- Interactive and audio-reactive wallpapers
- Playlists
- Screen saver integration

## Development

Open `WallpaperStudio.xcodeproj` in Xcode.

The project is intended to be developed with modern macOS SDKs, including macOS 27, while avoiding unnecessary OS-version restrictions unless a feature specifically requires them.

## License

Wallpaper Studio is available under the MIT License.
