import AppKit
import SwiftUI

@MainActor
class PopoverController {
    private let popover: NSPopover
    private weak var appState: AppState?

    init(appState: AppState, onOpenSettings: @escaping () -> Void, onRefresh: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.appState = appState
        self.popover = NSPopover()

        let dismiss: () -> Void = { [weak popover] in
            popover?.performClose(nil)
        }

        let contentView = PopoverContentView(
            appState: appState,
            onOpenSettings: onOpenSettings,
            onRefresh: onRefresh,
            onQuit: onQuit,
            onDismiss: dismiss
        )

        popover.contentSize = NSSize(width: 380, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    func toggle(relativeTo rect: NSRect, of view: NSView) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: rect, of: view, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
