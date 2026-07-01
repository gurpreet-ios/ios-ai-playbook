// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIPlaybookSampleApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AIPlaybookSampleApp",
            targets: ["AIPlaybookSampleApp"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AIPlaybookSampleApp",
            dependencies: []),
    ]
)
