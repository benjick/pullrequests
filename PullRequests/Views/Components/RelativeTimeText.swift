import SwiftUI

struct RelativeTimeText: View {
    let date: Date
    var prefix: String?

    @State private var now = Date()

    var body: some View {
        Text(formattedText)
            .onAppear { startTimer() }
    }

    private var formattedText: String {
        let interval = now.timeIntervalSince(date)
        let relative: String

        if interval < 60 {
            relative = "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            relative = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            relative = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            relative = "\(days)d ago"
        }

        if let prefix = prefix {
            return "\(prefix) \(relative)"
        }
        return relative
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                now = Date()
            }
        }
    }
}
