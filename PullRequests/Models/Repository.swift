import Foundation

struct Repository: Codable, Equatable, Identifiable, Hashable {
    let owner: String
    let name: String

    var id: String { "\(owner)/\(name)" }

    init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }

    init?(fullName: String) {
        let parts = fullName.split(separator: "/")
        guard parts.count == 2 else { return nil }
        self.owner = String(parts[0])
        self.name = String(parts[1])
    }
}
