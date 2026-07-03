// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MovieSearchUIKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MovieSearchUIKit",
            targets: ["MovieSearchUIKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MovieSearchUIKit",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MovieSearchUIKitTests",
            dependencies: ["MovieSearchUIKit"],
            path: "Tests"
        )
    ]
)
