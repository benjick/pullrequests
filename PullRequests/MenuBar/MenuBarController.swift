import AppKit

@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popoverController: PopoverController?
    private weak var appState: AppState?

    var onOpenSettings: (() -> Void)?
    var onRefresh: (() -> Void)?
    var onQuit: (() -> Void)?

    func setup(appState: AppState) {
        self.appState = appState

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateIcon(button: button, reviewCount: 0, approvedCount: 0)
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popoverController = PopoverController(
            appState: appState,
            onOpenSettings: { [weak self] in self?.onOpenSettings?() },
            onRefresh: { [weak self] in self?.onRefresh?() },
            onQuit: { [weak self] in self?.onQuit?() }
        )
    }

    func updateBadge() {
        guard let button = statusItem?.button, let appState = appState else { return }
        updateIcon(button: button, reviewCount: appState.needsReviewCount, approvedCount: appState.approvedPRCount)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu(from: sender)
        } else {
            popoverController?.toggle(relativeTo: sender.bounds, of: sender)
        }
    }

    private func showContextMenu(from view: NSView) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r").target = self
        menu.addItem(withTitle: "Settings...", action: #selector(settingsClicked), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitClicked), keyEquivalent: "q").target = self
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func refreshClicked() { onRefresh?() }
    @objc private func settingsClicked() { onOpenSettings?() }
    @objc private func quitClicked() { onQuit?() }

    private func updateIcon(button: NSStatusBarButton, reviewCount: Int, approvedCount: Int) {
        let hasBadges = reviewCount > 0 || approvedCount > 0
        if hasBadges {
            button.image = makeBadgedIcon(reviewCount: reviewCount, approvedCount: approvedCount)
            button.image?.isTemplate = false
        } else {
            let image = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: "Pull Requests")
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            button.image = image?.withSymbolConfiguration(config)
            button.image?.isTemplate = true
        }
    }

    private func makeBadgedIcon(reviewCount: Int, approvedCount: Int) -> NSImage {
        // Calculate width: base icon + badges
        let badgeSize: CGFloat = 12
        let badgeGap: CGFloat = 2
        let iconWidth: CGFloat = 18
        var totalWidth = iconWidth

        var badges: [(text: String, color: NSColor)] = []
        if approvedCount > 0 {
            badges.append((approvedCount > 9 ? "9+" : "\(approvedCount)", .systemGreen))
        }
        if reviewCount > 0 {
            badges.append((reviewCount > 9 ? "9+" : "\(reviewCount)", .systemRed))
        }

        if !badges.isEmpty {
            totalWidth += CGFloat(badges.count) * badgeSize + CGFloat(badges.count) * badgeGap
        }

        let size = NSSize(width: totalWidth, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Draw base icon
            if let symbol = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                if let configured = symbol.withSymbolConfiguration(config) {
                    let iconRect = NSRect(x: 0, y: 1, width: iconWidth, height: 16)
                    configured.draw(in: iconRect)
                }
            }

            // Draw badges from right to left
            var badgeX = rect.width
            for badge in badges.reversed() {
                badgeX -= badgeSize
                let badgeRect = NSRect(
                    x: badgeX,
                    y: rect.height - badgeSize,
                    width: badgeSize,
                    height: badgeSize
                )
                badge.color.setFill()
                NSBezierPath(ovalIn: badgeRect).fill()

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: NSColor.white
                ]
                let textSize = (badge.text as NSString).size(withAttributes: attrs)
                let textRect = NSRect(
                    x: badgeRect.midX - textSize.width / 2,
                    y: badgeRect.midY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                (badge.text as NSString).draw(in: textRect, withAttributes: attrs)

                badgeX -= badgeGap
            }

            return true
        }
        return image
    }
}
