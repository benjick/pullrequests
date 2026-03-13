import Foundation
import Security

struct KeychainHelper {
    private let service = "com.pullrequests.app"
    private let account = "github-pat"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    func save(token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        // Delete existing item first
        delete()

        // Add new item using data protection keychain (no code-signing ACL)
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
