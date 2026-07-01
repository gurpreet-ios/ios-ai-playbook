// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UberClone",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UberClone",
            targets: ["UberClone"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UberClone",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "UberCloneTests",
            dependencies: ["UberClone"],
            path: "Tests"
        )
    ]
)
