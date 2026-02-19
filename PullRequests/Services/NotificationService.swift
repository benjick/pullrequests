import AppKit
import Foundation
import UserNotifications

@MainActor
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendTest() {
        let content = UNMutableNotificationContent()
        content.title = "Review requested"
        content.subtitle = "octocat/Hello-World"
        content.body = "Add dark mode support"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func send(change: PRChange) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch change.kind {
        case .newComment(let author, let body):
            content.title = "\(author) commented on #\(change.prID.split(separator: "#").last ?? "")"
            content.subtitle = change.repoName
            content.body = String(body.prefix(200))

        case .reviewStatusChanged(_, let to):
            let statusText: String
            switch to {
            case .approved: statusText = "approved"
            case .changesRequested: statusText = "requested changes on"
            case .pending: statusText = "reviewed"
            case .none: return
            }
            content.title = "PR \(statusText)"
            content.subtitle = change.repoName
            content.body = change.prTitle

        case .ciFinished(let status):
            content.title = "CI \(status == .success ? "passed" : "failed")"
            content.subtitle = change.repoName
            content.body = change.prTitle

        case .reviewRequested:
            content.title = "Review requested"
            content.subtitle = change.repoName
            content.body = change.prTitle
        }

        content.userInfo = ["url": change.prURL]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // Handle notification click — open PR in browser
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            Task { @MainActor in
                NSWorkspace.shared.open(url)
            }
        }
        completionHandler()
    }

    // Show notification even when app is foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
