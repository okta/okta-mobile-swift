// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "AuthFoundation",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9),
        .tvOS(.v10),
        .watchOS(.v7),
        .macOS(.v10_11),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "AuthFoundation", targets: ["AuthFoundation"]),
        .library(name: "OktaOAuth2", targets: ["OktaOAuth2"]),
        .library(name: "OktaDirectAuth", targets: ["OktaDirectAuth"]),
        .library(name: "WebAuthenticationUI", targets: ["WebAuthenticationUI"])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "AuthFoundation",
                dependencies: [],
                resources: [.process("Resources")]),
        .target(name: "OktaOAuth2",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                resources: [.process("Resources")]),
        .target(name: "OktaDirectAuth",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                resources: [.process("Resources")]),
        .target(name: "WebAuthenticationUI",
                dependencies: [
                    .target(name: "OktaOAuth2")
                ],
                resources: [.process("Resources")]),
    ] + [
        .target(name: "TestCommon",
                dependencies: ["AuthFoundation"],
                path: "Tests/TestCommon"),
        .testTarget(name: "AuthFoundationTests",
                    dependencies: ["AuthFoundation", "TestCommon"],
                    resources: [ .copy("MockResponses") ]),
        .testTarget(name: "OktaOAuth2Tests",
                    dependencies: ["OktaOAuth2", "TestCommon"],
                    resources: [ .copy("MockResponses") ]),
        .testTarget(name: "OktaDirectAuthTests",
                    dependencies: ["OktaDirectAuth", "TestCommon"],
                    resources: [ .copy("MockResponses") ]),
        .testTarget(name: "WebAuthenticationUITests",
                    dependencies: ["WebAuthenticationUI", "TestCommon"],
                    resources: [ .copy("MockResponses") ])
    ],
    swiftLanguageVersions: [.v5]
)

#if swift(>=5.6)
    package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
