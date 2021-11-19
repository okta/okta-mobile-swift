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
                 targets: [ "OktaIdx" ])
    ],
    targets: [
        .target(name: "OktaIdx",
                exclude: ["Info.plist"]),
        .target(name: "TestCommon",
                dependencies: [ "OktaIdx" ],
                path: "Tests/TestCommon",
                resources: [ .copy("SampleResponses") ]),
        .testTarget(name: "OktaIdxTests",
                    dependencies: [ "OktaIdx", "TestCommon" ],
                    exclude: ["Info.plist"])
    ]
)
