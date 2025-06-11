// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let strictConcurrencyEnabled = true
extension Array<SwiftSetting> {
    static var common: Self {
        [
            .enableUpcomingFeature("ExistentialAny"),
        ]
    }

    static var libraryTarget: Self {
        if strictConcurrencyEnabled {
            return common + [
                .enableExperimentalFeature("StrictConcurrency=complete"),
            ]
        } else {
            return common
        }
    }

    static var testTarget: Self {
        common
    }
}

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
                 branch: "OKTA-930344-IDXUpdates"),
        .package(url: "https://github.com/apple/swift-docc-plugin",
                 from: "1.4.0")
    ],
    targets: [
        .target(name: "OktaIdx",
                dependencies: [
                    .product(name: "AuthFoundation", package: "okta-mobile-swift")
                ],
                resources: [.process("Resources")],
                swiftSettings: .libraryTarget),
        .target(name: "TestCommon",
                dependencies: ["OktaIdx"],
                path: "Tests/TestCommon",
                swiftSettings: .testTarget),
        .testTarget(name: "OktaIdxTests",
                    dependencies: ["OktaIdx", "TestCommon"],
                    resources: [.copy("SampleResponses")],
                    swiftSettings: .testTarget)
    ],
    swiftLanguageModes: [.v6]
)
