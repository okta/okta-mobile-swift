// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OktaIdx",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v11)
    ],
    products: [
        .library(name: "OktaIdx",
                 type: .dynamic,
                 targets: [ "OktaIdx" ])
    ],
    targets: [
        .target(name: "OktaIdx"),
    ] + [
        .target(name: "TestCommon",
                dependencies: [ "OktaIdx" ],
                path: "Tests/Common"),
        .testTarget(name: "OktaIdxTests",
                    dependencies: [
                        "OktaIdx",
                        "TestCommon"
                    ])
    ]
)
