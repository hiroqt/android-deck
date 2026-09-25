// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacDeck",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacDeck",
            targets: ["MacDeck"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacDeck",
            dependencies: [],
            path: "Sources/MacDeck"
        ),
        .testTarget(
            name: "MacDeckTests",
            dependencies: ["MacDeck"],
            path: "Tests/MacDeckTests"
        )
    ]
)
