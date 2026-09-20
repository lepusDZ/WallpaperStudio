//
//  BenchmarkVideo.swift
//  WallpaperStudio
//
//  Created by Dmytro Zaichenko on 2026-09-19.
//


import AppKit
import AVFoundation
import Combine
import CoreMedia
import Darwin
import Foundation
import OSLog

struct BenchmarkVideo: Identifiable, Hashable, Sendable {

    let id: String
    let label: String
    let url: URL
}

enum BenchmarkCatalog {

    static let directoryURL =
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("wallpapers")

    static let videos: [BenchmarkVideo] = [
        BenchmarkVideo(
            id: "1080p30",
            label: "1080p30",
            url: directoryURL
                .appendingPathComponent("1080p30fps.mp4")
        ),
        BenchmarkVideo(
            id: "1080p60",
            label: "1080p60",
            url: directoryURL
                .appendingPathComponent("1080p60fps.mp4")
        ),
        BenchmarkVideo(
            id: "4k30",
            label: "4K30",
            url: directoryURL
                .appendingPathComponent("4k30fps.mp4")
        ),
        BenchmarkVideo(
            id: "4k60",
            label: "4K60",
            url: directoryURL
                .appendingPathComponent("4k60fps.mp4")
        )
    ]
}

enum BenchmarkPlaybackPath: String, Sendable {
    case reference = "Plain AVFoundation"
    case wallpaperStudio = "Wallpaper Studio"
}

struct VideoMetadata: Sendable {

    let width: Int
    let height: Int
    let fps: Double
    let codec: String
    let bitrateMbps: Double

    var resolution: String {
        "\(width) × \(height)"
    }
}

struct PerformanceSample: Sendable {

    let elapsedSeconds: Double
    let cpuPercent: Double
    let memoryMB: Double
}

struct BenchmarkRunResult: Sendable {

    let video: BenchmarkVideo
    let metadata: VideoMetadata
    let playbackPath: BenchmarkPlaybackPath
    let samples: [PerformanceSample]

    var averageCPU: Double {
        let values = samples
            .filter { $0.elapsedSeconds > 0 }
            .map(\.cpuPercent)

        guard !values.isEmpty else {
            return 0
        }

        return values.reduce(0, +)
            / Double(values.count)
    }

    var peakCPU: Double {
        samples
            .map(\.cpuPercent)
            .max()
            ?? 0
    }

    var initialMemoryMB: Double {
        samples.first?.memoryMB ?? 0
    }

    var finalMemoryMB: Double {
        samples.last?.memoryMB ?? 0
    }

    var peakMemoryMB: Double {
        samples
            .map(\.memoryMB)
            .max()
            ?? 0
    }

    var memoryDeltaMB: Double {
        finalMemoryMB - initialMemoryMB
    }
}

struct BenchmarkReportFiles {
    let markdown: URL
    let summaryCSV: URL
    let samplesCSV: URL
}

@MainActor
final class DebugPerformanceBenchmark: ObservableObject {

    @Published
    private(set) var isRunning = false

    @Published
    private(set) var progress = 0.0

    @Published
    private(set) var statusText = "Idle"

    @Published
    private(set) var lastReportURL: URL?

    private let engine: WallpaperEngine

    private var benchmarkTask:
        Task<Void, Never>?

    init(
        engine: WallpaperEngine
    ) {
        self.engine = engine
    }

    // MARK: - Public Controls

    func runQuickSuite() {
        startSuite(
            durationSeconds: 60,
            sampleIntervalSeconds: 10,
            name: "Quick"
        )
    }

    func runFullSuite() {
        startSuite(
            durationSeconds: 600,
            sampleIntervalSeconds: 30,
            name: "Full-Day-9"
        )
    }

    func cancel() {
        benchmarkTask?.cancel()
    }

    // MARK: - Suite

    private func startSuite(
        durationSeconds: Int,
        sampleIntervalSeconds: Int,
        name: String
    ) {
        guard !isRunning else {
            return
        }

        isRunning = true
        progress = 0
        statusText = "Preparing benchmark..."

        benchmarkTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let reportFiles =
                    try await executeSuite(
                        durationSeconds:
                            durationSeconds,
                        sampleIntervalSeconds:
                            sampleIntervalSeconds,
                        suiteName: name
                    )

                lastReportURL =
                    reportFiles.markdown

                statusText =
                    "Benchmark complete"

                progress = 1

                Logger.performance.info(
                    "Benchmark complete: \(reportFiles.markdown.path, privacy: .public)"
                )

                NSWorkspace.shared
                    .activateFileViewerSelecting(
                        [
                            reportFiles.markdown,
                            reportFiles.summaryCSV,
                            reportFiles.samplesCSV
                        ]
                    )
            } catch is CancellationError {
                statusText =
                    "Benchmark cancelled"

                Logger.performance.info(
                    "Benchmark cancelled"
                )
            } catch {
                statusText =
                    "Benchmark failed"

                Logger.performance.error(
                    "Benchmark failed: \(error.localizedDescription, privacy: .public)"
                )
            }

            isRunning = false
            benchmarkTask = nil
        }
    }

    private func executeSuite(
        durationSeconds: Int,
        sampleIntervalSeconds: Int,
        suiteName: String
    ) async throws -> BenchmarkReportFiles {
        try validateBenchmarkFiles()

        let previousVideoURL =
            engine.videoURL

        let previousState =
            engine.state

        let previousScalingMode =
            engine.scalingMode

        engine.stop()

        defer {
            restoreEngine(
                videoURL: previousVideoURL,
                state: previousState,
                scalingMode:
                    previousScalingMode
            )
        }

        let videos =
            BenchmarkCatalog.videos

        let totalRuns =
            videos.count * 2

        var completedRuns = 0
        var results: [BenchmarkRunResult] = []

        for video in videos {
            try Task.checkCancellation()

            statusText =
                "Reading \(video.label) metadata..."

            let metadata =
                try await VideoMetadataLoader
                    .load(from: video.url)

            let referenceResult =
                try await benchmarkReference(
                    video: video,
                    metadata: metadata,
                    durationSeconds:
                        durationSeconds,
                    sampleIntervalSeconds:
                        sampleIntervalSeconds,
                    runIndex: completedRuns,
                    totalRuns: totalRuns
                )

            results.append(
                referenceResult
            )

            completedRuns += 1

            let wallpaperResult =
                try await benchmarkWallpaperStudio(
                    video: video,
                    metadata: metadata,
                    durationSeconds:
                        durationSeconds,
                    sampleIntervalSeconds:
                        sampleIntervalSeconds,
                    runIndex: completedRuns,
                    totalRuns: totalRuns
                )

            results.append(
                wallpaperResult
            )

            completedRuns += 1
        }

        return try BenchmarkReportWriter.write(
            results: results,
            suiteName: suiteName,
            durationSeconds:
                durationSeconds,
            sampleIntervalSeconds:
                sampleIntervalSeconds
        )
    }

    // MARK: - Individual Runs

    private func benchmarkReference(
        video: BenchmarkVideo,
        metadata: VideoMetadata,
        durationSeconds: Int,
        sampleIntervalSeconds: Int,
        runIndex: Int,
        totalRuns: Int
    ) async throws -> BenchmarkRunResult {
        guard let screen =
            NSScreen.main
                ?? NSScreen.screens.first
        else {
            throw BenchmarkError.noScreen
        }

        statusText =
            "\(video.label): plain AVFoundation"

        Logger.performance.info(
            "Benchmarking \(video.label, privacy: .public) with plain AVFoundation"
        )

        let referencePlayer =
            AVFoundationReferencePlayer(
                sourceURL: video.url,
                screen: screen
            )

        referencePlayer.start()

        defer {
            referencePlayer.stop()
        }

        try await sleep(
            seconds: 5
        )

        let samples =
            try await collectSamples(
                durationSeconds:
                    durationSeconds,
                sampleIntervalSeconds:
                    sampleIntervalSeconds,
                runIndex: runIndex,
                totalRuns: totalRuns
            )

        return BenchmarkRunResult(
            video: video,
            metadata: metadata,
            playbackPath: .reference,
            samples: samples
        )
    }

    private func benchmarkWallpaperStudio(
        video: BenchmarkVideo,
        metadata: VideoMetadata,
        durationSeconds: Int,
        sampleIntervalSeconds: Int,
        runIndex: Int,
        totalRuns: Int
    ) async throws -> BenchmarkRunResult {
        statusText =
            "\(video.label): Wallpaper Studio"

        Logger.performance.info(
            "Benchmarking \(video.label, privacy: .public) with Wallpaper Studio"
        )

        engine.stop()

        guard engine.setVideoURL(
            video.url
        ) else {
            throw BenchmarkError
                .unableToSetVideo
        }

        engine.setScalingMode(
            .fill
        )

        guard engine.start() else {
            throw BenchmarkError
                .unableToStartWallpaper
        }

        defer {
            engine.stop()
        }

        try await sleep(
            seconds: 5
        )

        let samples =
            try await collectSamples(
                durationSeconds:
                    durationSeconds,
                sampleIntervalSeconds:
                    sampleIntervalSeconds,
                runIndex: runIndex,
                totalRuns: totalRuns
            )

        return BenchmarkRunResult(
            video: video,
            metadata: metadata,
            playbackPath:
                .wallpaperStudio,
            samples: samples
        )
    }

    // MARK: - Sampling

    private func collectSamples(
        durationSeconds: Int,
        sampleIntervalSeconds: Int,
        runIndex: Int,
        totalRuns: Int
    ) async throws -> [PerformanceSample] {
        guard var previous =
            ResourceMonitor.snapshot()
        else {
            throw BenchmarkError
                .unableToReadResources
        }

        let startTime =
            previous.wallTime

        var samples: [PerformanceSample] = [
            PerformanceSample(
                elapsedSeconds: 0,
                cpuPercent: 0,
                memoryMB:
                    previous.memoryMB
            )
        ]

        while true {
            try Task.checkCancellation()

            let elapsed =
                previous.wallTime - startTime

            if elapsed >=
                Double(durationSeconds) {
                break
            }

            let remaining =
                Double(durationSeconds)
                - elapsed

            let sleepDuration =
                min(
                    Double(
                        sampleIntervalSeconds
                    ),
                    remaining
                )

            try await sleep(
                seconds: sleepDuration
            )

            guard let current =
                ResourceMonitor.snapshot()
            else {
                throw BenchmarkError
                    .unableToReadResources
            }

            let wallDelta =
                current.wallTime
                - previous.wallTime

            let cpuDelta =
                current.cpuTime
                - previous.cpuTime

            let cpuPercent =
                wallDelta > 0
                ? (cpuDelta / wallDelta)
                    * 100
                : 0

            let totalElapsed =
                current.wallTime
                - startTime

            samples.append(
                PerformanceSample(
                    elapsedSeconds:
                        totalElapsed,
                    cpuPercent:
                        cpuPercent,
                    memoryMB:
                        current.memoryMB
                )
            )

            previous = current

            let runProgress =
                min(
                    totalElapsed
                    / Double(
                        durationSeconds
                    ),
                    1
                )

            progress =
                (
                    Double(runIndex)
                    + runProgress
                )
                / Double(totalRuns)

            statusText =
                "\(Int(progress * 100))% complete"
        }

        return samples
    }

    // MARK: - Validation / Restoration

    private func validateBenchmarkFiles()
        throws {

        let missing =
            BenchmarkCatalog.videos
                .filter {
                    !FileManager.default
                        .fileExists(
                            atPath:
                                $0.url.path
                        )
                }

        guard missing.isEmpty else {
            throw BenchmarkError
                .missingFiles(
                    missing.map(
                        \.url.path
                    )
                )
        }
    }

    private func restoreEngine(
        videoURL: URL?,
        state: WallpaperEngineState,
        scalingMode: WallpaperScalingMode
    ) {
        engine.stop()

        engine.setScalingMode(
            scalingMode
        )

        guard let videoURL else {
            engine.clearVideoURL()
            return
        }

        _ = engine.setVideoURL(
            videoURL
        )

        switch state {
        case .stopped:
            break

        case .running:
            _ = engine.start()

        case .paused:
            _ = engine.start()
            engine.pause()
        }
    }

    private func sleep(
        seconds: Double
    ) async throws {
        try await Task.sleep(
            nanoseconds:
                UInt64(
                    seconds
                    * 1_000_000_000
                )
        )
    }
}

// MARK: - Resource Monitoring

private struct ResourceSnapshot {

    let wallTime: TimeInterval
    let cpuTime: Double
    let memoryMB: Double
}

private enum ResourceMonitor {

    static func snapshot()
        -> ResourceSnapshot? {

        var usage = rusage()

        guard getrusage(
            RUSAGE_SELF,
            &usage
        ) == 0 else {
            return nil
        }

        let userCPU =
            seconds(
                usage.ru_utime
            )

        let systemCPU =
            seconds(
                usage.ru_stime
            )

        guard let memoryMB =
            residentMemoryMB()
        else {
            return nil
        }

        return ResourceSnapshot(
            wallTime:
                Date()
                    .timeIntervalSinceReferenceDate,
            cpuTime:
                userCPU + systemCPU,
            memoryMB:
                memoryMB
        )
    }

    private static func seconds(
        _ value: timeval
    ) -> Double {
        Double(value.tv_sec)
        + Double(value.tv_usec)
            / 1_000_000
    }

    private static func residentMemoryMB()
        -> Double? {

        var info =
            mach_task_basic_info()

        let infoCount =
            MemoryLayout<
                mach_task_basic_info
            >.stride
            / MemoryLayout<
                natural_t
            >.stride

        var count =
            mach_msg_type_number_t(
                infoCount
            )

        let result:
            kern_return_t =
                withUnsafeMutablePointer(
                    to: &info
                ) { pointer in

                    pointer
                        .withMemoryRebound(
                            to:
                                integer_t.self,
                            capacity:
                                infoCount
                        ) {
                            task_info(
                                mach_task_self_,
                                task_flavor_t(
                                    MACH_TASK_BASIC_INFO
                                ),
                                $0,
                                &count
                            )
                        }
                }

        guard result ==
            KERN_SUCCESS
        else {
            return nil
        }

        return Double(
            info.resident_size
        )
        / 1_048_576
    }
}

// MARK: - Metadata

private enum VideoMetadataLoader {

    static func load(
        from url: URL
    ) async throws -> VideoMetadata {
        let asset =
            AVURLAsset(url: url)

        let tracks =
            try await asset
                .loadTracks(
                    withMediaType:
                        .video
                )

        guard let track =
            tracks.first
        else {
            throw BenchmarkError
                .missingVideoTrack
        }

        let naturalSize =
            try await track.load(
                .naturalSize
            )

        let transform =
            try await track.load(
                .preferredTransform
            )

        let transformedSize =
            naturalSize
                .applying(transform)

        let fps =
            try await track.load(
                .nominalFrameRate
            )

        let bitrate =
            try await track.load(
                .estimatedDataRate
            )

        let descriptions =
            try await track.load(
                .formatDescriptions
            )

        return VideoMetadata(
            width:
                Int(
                    abs(
                        transformedSize.width
                    )
                    .rounded()
                ),
            height:
                Int(
                    abs(
                        transformedSize.height
                    )
                    .rounded()
                ),
            fps:
                Double(fps),
            codec:
                codecName(
                    from:
                        descriptions.first
                ),
            bitrateMbps:
                Double(bitrate)
                / 1_000_000
        )
    }

    private static func codecName(
        from description:
            CMFormatDescription?
    ) -> String {
        guard let description else {
            return "Unknown"
        }

        let subtype =
            CMFormatDescriptionGetMediaSubType(
                description
            )

        let bytes: [UInt8] = [
            UInt8(
                (subtype >> 24)
                & 0xFF
            ),
            UInt8(
                (subtype >> 16)
                & 0xFF
            ),
            UInt8(
                (subtype >> 8)
                & 0xFF
            ),
            UInt8(
                subtype & 0xFF
            )
        ]

        let fourCC =
            String(
                bytes: bytes,
                encoding: .ascii
            )
            ?? "Unknown"

        switch fourCC {
        case "avc1", "avc3":
            return "H.264"

        case "hvc1", "hev1":
            return "HEVC"

        default:
            return fourCC
        }
    }
}

// MARK: - Report Writer

private enum BenchmarkReportWriter {

    static func write(
        results: [BenchmarkRunResult],
        suiteName: String,
        durationSeconds: Int,
        sampleIntervalSeconds: Int
    ) throws -> BenchmarkReportFiles {
        let directory =
            try makeOutputDirectory(
                suiteName:
                    suiteName
            )

        let markdownURL =
            directory
                .appendingPathComponent(
                    "report.md"
                )

        let summaryCSVURL =
            directory
                .appendingPathComponent(
                    "summary.csv"
                )

        let samplesCSVURL =
            directory
                .appendingPathComponent(
                    "samples.csv"
                )

        try markdown(
            results: results,
            suiteName:
                suiteName,
            durationSeconds:
                durationSeconds,
            sampleIntervalSeconds:
                sampleIntervalSeconds
        )
        .write(
            to: markdownURL,
            atomically: true,
            encoding: .utf8
        )

        try summaryCSV(
            results: results
        )
        .write(
            to: summaryCSVURL,
            atomically: true,
            encoding: .utf8
        )

        try samplesCSV(
            results: results
        )
        .write(
            to: samplesCSVURL,
            atomically: true,
            encoding: .utf8
        )

        return BenchmarkReportFiles(
            markdown:
                markdownURL,
            summaryCSV:
                summaryCSVURL,
            samplesCSV:
                samplesCSVURL
        )
    }

    private static func makeOutputDirectory(
        suiteName: String
    ) throws -> URL {
        let fileManager =
            FileManager.default

        let documents =
            fileManager.urls(
                for:
                    .documentDirectory,
                in:
                    .userDomainMask
            ).first!

        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "yyyy-MM-dd_HH-mm-ss"

        let timestamp =
            formatter.string(
                from: Date()
            )

        let directory =
            documents
                .appendingPathComponent(
                    "WallpaperStudio"
                )
                .appendingPathComponent(
                    "Benchmarks"
                )
                .appendingPathComponent(
                    "\(timestamp)_\(suiteName)"
                )

        try fileManager
            .createDirectory(
                at: directory,
                withIntermediateDirectories:
                    true
            )

        return directory
    }

    private static func markdown(
        results: [BenchmarkRunResult],
        suiteName: String,
        durationSeconds: Int,
        sampleIntervalSeconds: Int
    ) -> String {
        var output = """
        # Wallpaper Studio Performance Baseline

        Suite: \(suiteName)

        Duration per playback path: \(durationSeconds) seconds

        Sample interval: \(sampleIntervalSeconds) seconds

        ## Baseline comparison

        | Video | Resolution | FPS | Codec | Bitrate | Reference Avg CPU | Wallpaper Avg CPU | Reference Memory Δ | Wallpaper Memory Δ | Assessment |
        | --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |

        """

        for video in BenchmarkCatalog.videos {
            guard
                let reference =
                    result(
                        for: video,
                        path:
                            .reference,
                        in: results
                    ),
                let wallpaper =
                    result(
                        for: video,
                        path:
                            .wallpaperStudio,
                        in: results
                    )
            else {
                continue
            }

            let assessment =
                assessment(
                    reference:
                        reference,
                    wallpaper:
                        wallpaper
                )

            output +=
                "| \(video.label) "
                + "| \(reference.metadata.resolution) "
                + "| \(format(reference.metadata.fps)) "
                + "| \(reference.metadata.codec) "
                + "| \(format(reference.metadata.bitrateMbps)) Mb/s "
                + "| \(format(reference.averageCPU))% "
                + "| \(format(wallpaper.averageCPU))% "
                + "| \(format(reference.memoryDeltaMB)) MB "
                + "| \(format(wallpaper.memoryDeltaMB)) MB "
                + "| \(assessment) |\n"
        }

        output += """

        ## Detailed runs

        | Video | Playback path | Avg CPU | Peak CPU | Initial Memory | Final Memory | Peak Memory | Memory Δ |
        | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |

        """

        for result in results {
            output +=
                "| \(result.video.label) "
                + "| \(result.playbackPath.rawValue) "
                + "| \(format(result.averageCPU))% "
                + "| \(format(result.peakCPU))% "
                + "| \(format(result.initialMemoryMB)) MB "
                + "| \(format(result.finalMemoryMB)) MB "
                + "| \(format(result.peakMemoryMB)) MB "
                + "| \(format(result.memoryDeltaMB)) MB |\n"
        }

        output += """

        ## Interpretation

        The plain AVFoundation run is the reference path. Wallpaper Studio should remain reasonably close to it during steady-state playback.

        Memory should reach a stable range rather than continuously increasing.

        "Healthy relative to reference" means the Wallpaper Studio CPU cost stayed reasonably close to the plain AVFoundation reference and no large memory growth was observed.

        Hardware decoding is not directly asserted by this report. The assessment is a heuristic based on stable playback cost relative to the native AVFoundation reference.

        Activity Monitor's Energy Impact value is not synthesized here. CPU and memory are recorded directly and reproducibly instead.

        Raw measurements are available in `samples.csv`.

        """

        return output
    }

    private static func summaryCSV(
        results: [BenchmarkRunResult]
    ) -> String {
        var output =
            "video,path,resolution,fps,codec,bitrate_mbps,avg_cpu_percent,peak_cpu_percent,initial_memory_mb,final_memory_mb,peak_memory_mb,memory_delta_mb\n"

        for result in results {
            output += [
                result.video.label,
                result.playbackPath.rawValue,
                result.metadata.resolution,
                format(
                    result.metadata.fps
                ),
                result.metadata.codec,
                format(
                    result.metadata
                        .bitrateMbps
                ),
                format(
                    result.averageCPU
                ),
                format(
                    result.peakCPU
                ),
                format(
                    result.initialMemoryMB
                ),
                format(
                    result.finalMemoryMB
                ),
                format(
                    result.peakMemoryMB
                ),
                format(
                    result.memoryDeltaMB
                )
            ]
            .map(csvEscape)
            .joined(separator: ",")

            output += "\n"
        }

        return output
    }

    private static func samplesCSV(
        results: [BenchmarkRunResult]
    ) -> String {
        var output =
            "video,path,elapsed_seconds,cpu_percent,memory_mb\n"

        for result in results {
            for sample in result.samples {
                output += [
                    result.video.label,
                    result.playbackPath.rawValue,
                    format(
                        sample.elapsedSeconds
                    ),
                    format(
                        sample.cpuPercent
                    ),
                    format(
                        sample.memoryMB
                    )
                ]
                .map(csvEscape)
                .joined(separator: ",")

                output += "\n"
            }
        }

        return output
    }

    private static func result(
        for video: BenchmarkVideo,
        path: BenchmarkPlaybackPath,
        in results: [BenchmarkRunResult]
    ) -> BenchmarkRunResult? {
        results.first {
            $0.video.id == video.id
            && $0.playbackPath == path
        }
    }

    private static func assessment(
        reference: BenchmarkRunResult,
        wallpaper: BenchmarkRunResult
    ) -> String {
        let referenceCPU =
            max(
                reference.averageCPU,
                0.1
            )

        let cpuRatio =
            wallpaper.averageCPU
            / referenceCPU

        if wallpaper.memoryDeltaMB > 128 {
            return "Investigate memory growth"
        }

        if cpuRatio <= 1.5 {
            return "Healthy relative to reference"
        }

        if cpuRatio <= 2.0 {
            return "Review CPU overhead"
        }

        return "Investigate CPU overhead"
    }

    private static func format(
        _ value: Double
    ) -> String {
        String(
            format: "%.2f",
            value
        )
    }

    private static func csvEscape(
        _ value: String
    ) -> String {
        if value.contains(",")
            || value.contains("\"")
            || value.contains("\n") {

            return "\""
                + value.replacingOccurrences(
                    of: "\"",
                    with: "\"\""
                )
                + "\""
        }

        return value
    }
}

// MARK: - Errors

private enum BenchmarkError:
    LocalizedError {

    case missingFiles([String])
    case noScreen
    case unableToSetVideo
    case unableToStartWallpaper
    case unableToReadResources
    case missingVideoTrack

    var errorDescription: String? {
        switch self {
        case .missingFiles(let paths):
            return
                "Missing benchmark files:\n"
                + paths.joined(
                    separator: "\n"
                )

        case .noScreen:
            return
                "No display is available."

        case .unableToSetVideo:
            return
                "Unable to set benchmark video."

        case .unableToStartWallpaper:
            return
                "Wallpaper Studio could not start the benchmark video."

        case .unableToReadResources:
            return
                "Unable to read process CPU or memory information."

        case .missingVideoTrack:
            return
                "The video does not contain a video track."
        }
    }
}