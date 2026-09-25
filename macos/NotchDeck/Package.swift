// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NotchDeck",
            targets: ["NotchDeck"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NotchDeck",
            dependencies: [],
            path: "Sources/NotchDeck"
        ),
        .testTarget(
            name: "NotchDeckTests",
            dependencies: ["NotchDeck"],
            path: "Tests/NotchDeckTests"
        )
    ]
)
