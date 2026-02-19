import Foundation

extension Notification.Name {
    static let configChanged = Notification.Name("configChanged")
    static let tokenChanged = Notification.Name("tokenChanged")
}

@MainActor
class ConfigManager {
    static let shared = ConfigManager()

    private let defaults = UserDefaults.standard
    private let configKey = "com.pullrequests.config"

    private init() {}

    func load() -> AppConfig {
        guard let data = defaults.data(forKey: configKey) else {
            return .default
        }

        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            return .default
        }
    }

    func save(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            defaults.set(data, forKey: configKey)
            NotificationCenter.default.post(name: .configChanged, object: nil)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
