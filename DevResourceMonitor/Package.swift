// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevResourceMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DevResourceMonitor",
            targets: ["DevResourceMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DevResourceMonitor",
            path: "DevResourceMonitor",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
