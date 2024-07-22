// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Package definition for Studio.
*/

import PackageDescription

let package = Package(
    name: "Studio",
    platforms: [
        .visionOS("2.0"),
        .macOS("15.0"),
        .iOS("18.0")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Studio",
            targets: ["Studio"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Studio",
            dependencies: [])
    ]
)
