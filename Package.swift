// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PermissionFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PermissionFlow",
            targets: ["PermissionFlow"]
        ),
        .executable(
            name: "PermissionFlowDemo",
            targets: ["PermissionFlowDemo"]
        )
    ],
    targets: [
        .target(
            name: "PermissionFlow"
        ),
        .executableTarget(
            name: "PermissionFlowDemo",
            dependencies: ["PermissionFlow"]
        )
    ]
)
