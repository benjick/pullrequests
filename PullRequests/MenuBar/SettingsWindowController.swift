import AppKit
import SwiftUI

@MainActor
class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private weak var appState: AppState?

    private static let contentSize = NSSize(width: 550, height: 450)

    func setup(appState: AppState) {
        self.appState = appState
    }

    func showWindow() {
        if window == nil {
            createWindow()
        }

        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        guard let appState = appState else { return }

        // An AppKit tab view controller gives the standard settings toolbar
        // (one icon per tab). A SwiftUI TabView hosted in an NSWindow gets
        // squeezed into a single toolbar item on macOS 26, which then
        // collapses into the overflow menu.
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        tabs.transitionOptions = []

        func addTab<V: View>(_ title: String, _ symbol: String, _ view: V) {
            let host = NSHostingController(
                rootView: view.frame(minWidth: 450, maxWidth: .infinity, minHeight: 350, maxHeight: .infinity)
            )
            // Keep one window size for all tabs instead of resizing per tab.
            host.sizingOptions = []
            host.preferredContentSize = Self.contentSize
            // The tab controller copies the selected tab's title to the window.
            host.title = title
            let item = NSTabViewItem(viewController: host)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            tabs.addTabViewItem(item)
        }

        addTab("General", "gear", GeneralSettingsView(appState: appState))
        addTab("Repos", "folder", RepositoriesSettingsView(appState: appState))
        addTab("Notifications", "bell", NotificationsSettingsView(appState: appState))
        addTab("Filters", "line.3.horizontal.decrease", FiltersSettingsView(appState: appState))
        addTab("Hidden", "eye.slash", HiddenSettingsView(appState: appState))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.toolbarStyle = .preference
        window.setContentSize(Self.contentSize)
        window.minSize = NSSize(width: 450, height: 350)
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
