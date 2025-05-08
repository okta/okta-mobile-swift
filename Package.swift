// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "OktaIdx",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v7),
        .visionOS(.v1),
        .macOS(.v10_15),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "OktaIdx", targets: ["OktaIdx"])
    ],
    dependencies: [
        .package(url: "https://github.com/okta/okta-mobile-swift",
                 from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin",
                 from: "1.0.0")
    ],
    targets: [
        .target(name: "OktaIdx",
                dependencies: [
                    .product(name: "AuthFoundation", package: "okta-mobile-swift")
                ],
                resources: [.process("Resources")]),
        .target(name: "TestCommon",
                dependencies: ["OktaIdx"],
                path: "Tests/TestCommon"),
        .testTarget(name: "OktaIdxTests",
                    dependencies: ["OktaIdx", "TestCommon"],
                resources: [.copy("SampleResponses")])
    ],
    swiftLanguageVersions: [.v5]
)
