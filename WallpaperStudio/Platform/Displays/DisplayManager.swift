import Cocoa
import OSLog

@MainActor
final class DisplayManager: NSObject {

    private(set)
    var displays: [DisplayDescriptor] = []

    var onTopologyChange:
        (@MainActor (DisplayTopologyChange) -> Void)?

    private var isObserving = false

    override init() {
        super.init()
    }

    deinit {
        NotificationCenter.default
            .removeObserver(self)
    }

    func start() {
        guard !isObserving else {
            return
        }

        NotificationCenter.default
            .addObserver(
                self,
                selector:
                    #selector(
                        screenParametersDidChange
                    ),
                name:
                    NSApplication
                        .didChangeScreenParametersNotification,
                object: nil
            )

        isObserving = true

        refreshDisplays(
            reason:
                "Initial display discovery"
        )

        Logger.display.debug(
            "Started observing display topology changes"
        )
    }

    func stop() {
        guard isObserving else {
            return
        }

        NotificationCenter.default
            .removeObserver(
                self,
                name:
                    NSApplication
                        .didChangeScreenParametersNotification,
                object: nil
            )

        isObserving = false

        Logger.display.debug(
            "Stopped observing display topology changes"
        )
    }

    func screen(
        for displayID: DisplayID
    ) -> NSScreen? {
        NSScreen.screens.first {
            screen in

            DisplayDescriptor
                .identifier(
                    for: screen
                )
                == displayID
        }
    }

    // MARK: - Discovery

    @objc
    private func screenParametersDidChange() {
        refreshDisplays(
            reason:
                "Display topology changed"
        )
    }

    private func refreshDisplays(
        reason: String
    ) {
        let previous = displays

        let current =
            NSScreen.screens
                .compactMap(
                    DisplayDescriptor
                        .init(screen:)
                )
                .sorted {
                    $0.id < $1.id
                }

        displays = current

        let change =
            DisplayTopologyChange
                .compare(
                    previous:
                        previous,
                    current:
                        current
                )

        logDisplays(
            reason: reason,
            change: change
        )

        if !previous.isEmpty,
           change.hasChanges {

            onTopologyChange?(
                change
            )
        }
    }

    private func logDisplays(
        reason: String,
        change: DisplayTopologyChange
    ) {
        Logger.display.info(
            "\(reason, privacy: .public): \(self.displays.count) display(s)"
        )

        for display in displays {
            Logger.display.info(
                "\(display.logDescription, privacy: .public)"
            )
        }

        guard !change.previous.isEmpty,
              change.hasChanges
        else {
            return
        }

        Logger.display.info(
            "Topology diff: +\(change.added.count) / -\(change.removed.count) / ~\(change.updated.count)"
        )
    }
}
