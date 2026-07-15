// swift-tools-version:5.9
// This manifest exposes the platform-independent core of the app
// (config parsing, IRCC codes, and the network client) as a library so
// `swift build` / `swift test` can verify it on any machine with a Swift
// toolchain — no Xcode required. The iOS app itself is built from
// SonyBDPRemote.xcodeproj, which compiles these same files plus the
// SwiftUI layer.
import PackageDescription

let package = Package(
    name: "SonyBDPCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
    ],
    products: [
        .library(name: "SonyBDPCore", targets: ["SonyBDPCore"]),
    ],
    targets: [
        .target(
            name: "SonyBDPCore",
            path: "SonyBDPRemote",
            sources: [
                "Config/EnvConfig.swift",
                "Model/IRCCCommand.swift",
                "Network/BDPNetworkClient.swift",
            ]
        ),
        .testTarget(
            name: "SonyBDPCoreTests",
            dependencies: ["SonyBDPCore"],
            path: "Tests/SonyBDPCoreTests"
        ),
    ]
)
