// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PullRequests",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PullRequests",
            path: "PullRequests",
            exclude: ["Info.plist", "Resources"]
        )
    ]
)
