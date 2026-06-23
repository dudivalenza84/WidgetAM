// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MacMediaWidget",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "MacMediaWidget",
            path: "Sources/MacMediaWidget"
        )
    ]
)
