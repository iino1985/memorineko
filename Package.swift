// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "memo-neko",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "memo-neko",
            path: "Sources/memo-neko",
            resources: [.copy("Resources")]
        )
    ]
)
