// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicInterviewApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MusicInterviewApp",
            targets: ["MusicInterviewApp"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MusicInterviewApp",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MusicInterviewAppTests",
            dependencies: ["MusicInterviewApp"],
            path: "Tests"
        )
    ]
)
