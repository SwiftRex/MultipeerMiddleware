// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultipeerMiddleware",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "MultipeerCombine", targets: ["MultipeerCombine"]),
        .library(name: "MultipeerMiddleware", targets: ["MultipeerMiddleware"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftRex/SwiftRex.git", from: "0.8.8")
    ],
    targets: [
        .target(name: "MultipeerCombine", dependencies: []),
        .target(name: "MultipeerMiddleware", dependencies: [.product(name: "CombineRex", package: "SwiftRex"), "MultipeerCombine"]),
        .testTarget(name: "MultipeerCombineTests", dependencies: ["MultipeerCombine"]),
        .testTarget(name: "MultipeerMiddlewareTests", dependencies: ["MultipeerMiddleware"])
    ]
)
