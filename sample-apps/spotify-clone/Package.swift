// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpotifyClone",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SpotifyClone",
            targets: ["SpotifyClone"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpotifyClone",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SpotifyCloneTests",
            dependencies: ["SpotifyClone"],
            path: "Tests"
        )
    ]
)
