import Cocoa
import ColorSync
import CoreGraphics

struct DisplayDescriptor: Identifiable, Equatable {
    let id: DisplayID
    let cgDisplayID: CGDirectDisplayID
    let name: String

    let logicalFrame: CGRect
    let visibleFrame: CGRect
    let backingScaleFactor: CGFloat

    let pixelWidth: Int
    let pixelHeight: Int

    let currentRefreshRate: Double?
    let minimumRefreshRate: Double?
    let maximumRefreshRate: Double?
    let maximumFramesPerSecond: Int

    let vendorID: UInt32
    let modelID: UInt32
    let serialNumber: UInt32

    let isMain: Bool
    let isBuiltIn: Bool

    init(
        id: DisplayID,
        cgDisplayID: CGDirectDisplayID = 0,
        name: String,
        logicalFrame: CGRect,
        visibleFrame: CGRect? = nil,
        backingScaleFactor: CGFloat = 1,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        currentRefreshRate: Double? = nil,
        minimumRefreshRate: Double? = nil,
        maximumRefreshRate: Double? = nil,
        maximumFramesPerSecond: Int = 60,
        vendorID: UInt32 = 0,
        modelID: UInt32 = 0,
        serialNumber: UInt32 = 0,
        isMain: Bool = false,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.cgDisplayID = cgDisplayID
        self.name = name
        self.logicalFrame = logicalFrame
        self.visibleFrame = visibleFrame ?? logicalFrame
        self.backingScaleFactor = backingScaleFactor

        self.pixelWidth =
            pixelWidth
            ?? Int(logicalFrame.width * backingScaleFactor)

        self.pixelHeight =
            pixelHeight
            ?? Int(logicalFrame.height * backingScaleFactor)

        self.currentRefreshRate = currentRefreshRate
        self.minimumRefreshRate = minimumRefreshRate
        self.maximumRefreshRate = maximumRefreshRate
        self.maximumFramesPerSecond = maximumFramesPerSecond

        self.vendorID = vendorID
        self.modelID = modelID
        self.serialNumber = serialNumber

        self.isMain = isMain
        self.isBuiltIn = isBuiltIn
    }

    @MainActor
    init?(screen: NSScreen) {
        guard let cgDisplayID = screen.cgDirectDisplayID else {
            return nil
        }

        let displayMode =
            CGDisplayCopyDisplayMode(cgDisplayID)

        let currentRefreshRate =
            Self.validRefreshRate(
                displayMode?.refreshRate
            )

        let minimumRefreshRate =
            Self.refreshRate(
                fromInterval:
                    screen.maximumRefreshInterval
            )

        let maximumRefreshRate =
            Self.refreshRate(
                fromInterval:
                    screen.minimumRefreshInterval
            )

        self.init(
            id: Self.identifier(
                for: cgDisplayID
            ),
            cgDisplayID: cgDisplayID,
            name: screen.localizedName,
            logicalFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            backingScaleFactor:
                screen.backingScaleFactor,
            pixelWidth:
                displayMode?.pixelWidth
                ?? CGDisplayPixelsWide(
                    cgDisplayID
                ),
            pixelHeight:
                displayMode?.pixelHeight
                ?? CGDisplayPixelsHigh(
                    cgDisplayID
                ),
            currentRefreshRate:
                currentRefreshRate,
            minimumRefreshRate:
                minimumRefreshRate,
            maximumRefreshRate:
                maximumRefreshRate,
            maximumFramesPerSecond:
                screen.maximumFramesPerSecond,
            vendorID:
                CGDisplayVendorNumber(
                    cgDisplayID
                ),
            modelID:
                CGDisplayModelNumber(
                    cgDisplayID
                ),
            serialNumber:
                CGDisplaySerialNumber(
                    cgDisplayID
                ),
            isMain:
                CGDisplayIsMain(
                    cgDisplayID
                ) != 0,
            isBuiltIn:
                CGDisplayIsBuiltin(
                    cgDisplayID
                ) != 0
        )
    }

    @MainActor
    static func identifier(
        for screen: NSScreen
    ) -> DisplayID? {
        guard let cgDisplayID =
            screen.cgDirectDisplayID
        else {
            return nil
        }

        return identifier(
            for: cgDisplayID
        )
    }

    var logDescription: String {
        let currentRefresh =
            currentRefreshRate
                .map {
                    String(
                        format: "%.2f Hz",
                        $0
                    )
                }
                ?? "unknown"

        let refreshRange: String

        if let minimumRefreshRate,
           let maximumRefreshRate {

            refreshRange = String(
                format:
                    "%.2f...%.2f Hz",
                minimumRefreshRate,
                maximumRefreshRate
            )
        } else {
            refreshRange = "unknown"
        }

        return """
        Display "\(name)"
          ID: \(id.rawValue)
          CG display ID: \(cgDisplayID)
          Main: \(isMain), built-in: \(isBuiltIn)
          Logical frame: x=\(Self.format(logicalFrame.origin.x)), y=\(Self.format(logicalFrame.origin.y)), width=\(Self.format(logicalFrame.width)), height=\(Self.format(logicalFrame.height))
          Pixels: \(pixelWidth) x \(pixelHeight)
          Backing scale: \(Self.format(backingScaleFactor))x
          Refresh: current=\(currentRefresh), range=\(refreshRange), maxFPS=\(maximumFramesPerSecond)
        """
    }

    private static func identifier(
        for cgDisplayID: CGDirectDisplayID
    ) -> DisplayID {
        if let unmanagedUUID =
            CGDisplayCreateUUIDFromDisplayID(
                cgDisplayID
            ) {

            let uuid =
                unmanagedUUID
                    .takeRetainedValue()

            let uuidString =
                CFUUIDCreateString(
                    nil,
                    uuid
                ) as String

            return DisplayID(
                rawValue: uuidString
            )
        }

        let vendor =
            CGDisplayVendorNumber(
                cgDisplayID
            )

        let model =
            CGDisplayModelNumber(
                cgDisplayID
            )

        let serial =
            CGDisplaySerialNumber(
                cgDisplayID
            )

        return DisplayID(
            rawValue:
                "fallback-\(vendor)-\(model)-\(serial)-\(cgDisplayID)"
        )
    }

    private static func validRefreshRate(
        _ value: Double?
    ) -> Double? {
        guard let value,
              value > 0
        else {
            return nil
        }

        return value
    }

    private static func refreshRate(
        fromInterval interval: TimeInterval
    ) -> Double? {
        guard interval > 0 else {
            return nil
        }

        return 1 / interval
    }

    private static func format(
        _ value: CGFloat
    ) -> String {
        String(
            format: "%.2f",
            Double(value)
        )
    }
}

struct DisplayMatch: Equatable {
    let previous: DisplayDescriptor
    let current: DisplayDescriptor
}

enum DisplayAssignmentMatcher {

    static func match(
        previous: [DisplayDescriptor],
        current: [DisplayDescriptor]
    ) -> [DisplayMatch] {

        let previousByID =
            Dictionary(
                uniqueKeysWithValues:
                    previous.map {
                        ($0.id, $0)
                    }
            )

        return current
            .compactMap { currentDisplay in
                guard let previousDisplay =
                    previousByID[
                        currentDisplay.id
                    ]
                else {
                    return nil
                }

                return DisplayMatch(
                    previous:
                        previousDisplay,
                    current:
                        currentDisplay
                )
            }
            .sorted {
                $0.current.id
                    < $1.current.id
            }
    }
}

struct DisplayTopologyChange {
    let previous: [DisplayDescriptor]
    let current: [DisplayDescriptor]

    let added: [DisplayDescriptor]
    let removed: [DisplayDescriptor]
    let updated: [DisplayMatch]

    var hasChanges: Bool {
        !added.isEmpty
        || !removed.isEmpty
        || !updated.isEmpty
    }

    static func compare(
        previous: [DisplayDescriptor],
        current: [DisplayDescriptor]
    ) -> DisplayTopologyChange {

        let previousByID =
            Dictionary(
                uniqueKeysWithValues:
                    previous.map {
                        ($0.id, $0)
                    }
            )

        let currentByID =
            Dictionary(
                uniqueKeysWithValues:
                    current.map {
                        ($0.id, $0)
                    }
            )

        let added =
            current
                .filter {
                    previousByID[
                        $0.id
                    ] == nil
                }
                .sorted {
                    $0.id < $1.id
                }

        let removed =
            previous
                .filter {
                    currentByID[
                        $0.id
                    ] == nil
                }
                .sorted {
                    $0.id < $1.id
                }

        let updated =
            DisplayAssignmentMatcher
                .match(
                    previous: previous,
                    current: current
                )
                .filter {
                    $0.previous
                        != $0.current
                }

        return DisplayTopologyChange(
            previous: previous,
            current: current,
            added: added,
            removed: removed,
            updated: updated
        )
    }
}
