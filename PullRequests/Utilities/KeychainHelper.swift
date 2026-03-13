import Foundation

struct KeychainHelper {
    private static let tokenURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/pullrequests", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("token")
    }()

    func save(token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        let url = Self.tokenURL
        do {
            try data.write(to: url, options: [.atomic])
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600], ofItemAtPath: url.path)
            return true
        } catch {
            return false
        }
    }

    func load() -> String? {
        guard let data = try? Data(contentsOf: Self.tokenURL) else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func delete() {
        try? FileManager.default.removeItem(at: Self.tokenURL)
    }
}
