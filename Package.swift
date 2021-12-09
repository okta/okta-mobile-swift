// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthFoundation",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v7),
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "AuthFoundation", targets: ["AuthFoundation"]),
        .library(name: "OktaOAuth2", targets: ["OktaOAuth2"]),
        .library(name: "WebAuthenticationUI", targets: ["WebAuthenticationUI"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "AuthFoundation",
                dependencies: []),
        .target(name: "OktaOAuth2",
                dependencies: [
                    .target(name: "AuthFoundation")
                ]),
        .target(name: "WebAuthenticationUI",
                dependencies: [
                    .target(name: "OktaOAuth2")
                ]),
    ] + [
        .target(name: "TestCommon",
                dependencies: ["AuthFoundation"],
                path: "Tests/TestCommon"),
        .testTarget(name: "AuthFoundationTests",
                    dependencies: ["AuthFoundation"]),
        .testTarget(name: "OktaOAuth2Tests",
                    dependencies: ["OktaOAuth2", "TestCommon"],
                    resources: [ .copy("MockResponses") ]),
        .testTarget(name: "WebAuthenticationUITests",
                    dependencies: ["WebAuthenticationUI"])
    ]
)
