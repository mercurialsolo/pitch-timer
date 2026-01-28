// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PitchTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PitchTimer",
            targets: ["PitchTimer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PitchTimer",
            dependencies: [],
            path: "PitchTimer"
        )
    ]
)
