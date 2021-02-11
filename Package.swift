// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OktaIdx",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v10)
    ],
    products: [
        .library(name: "OktaIdx",
                 type: .dynamic,
                 targets: [ "OktaIdx" ])
    ],
    targets: [
        .target(name: "OktaIdx",
                exclude: ["Info.plist"]),
        .testTarget(name: "OktaIdxTests",
                    dependencies: [ "OktaIdx" ],
                    path: "Tests",
                    exclude: ["Info.plist"],
                    resources: [ .copy("Resources") ])
    ]
)
