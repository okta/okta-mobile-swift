// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
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
    name: "OktaClient",
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
        .library(name: "CommonSupport", targets: ["CommonSupport"]),
        .library(name: "JSON", targets: ["JSON"]),
        .library(name: "AuthFoundation", targets: ["CommonSupport", "JSON", "AuthFoundation"]),
        .library(name: "OAuth2Auth", targets: ["OAuth2Auth"]),
        .library(name: "OktaDirectAuth", targets: ["OktaDirectAuth"]),
        .library(name: "OktaIdxAuth", targets: ["OktaIdxAuth"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(name: "CommonSupport",
                swiftSettings: .libraryTarget),
        .target(name: "JSON",
                dependencies: ["CommonSupport"],
                swiftSettings: .libraryTarget),
        .target(name: "AuthFoundation",
                dependencies: ["CommonSupport", "JSON"],
                resources: [.process("Resources")],
                swiftSettings: .libraryTarget),
        .target(name: "OAuth2Auth",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                resources: [.process("Resources")],
                swiftSettings: .libraryTarget),
        .target(name: "OktaDirectAuth",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                resources: [.process("Resources")],
                swiftSettings: .libraryTarget),
        .target(name: "OktaIdxAuth",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                resources: [.process("Resources")],
                swiftSettings: .libraryTarget),
    ] + [
        .target(name: "TestCommon",
                dependencies: ["AuthFoundation"],
                path: "Tests/TestCommon",
                swiftSettings: .testTarget),
        .testTarget(name: "CommonSupportTests",
                    dependencies: ["CommonSupport", "TestCommon"],
                    swiftSettings: .testTarget),
        .testTarget(name: "JSONTests",
                    dependencies: ["JSON", "TestCommon"],
                    swiftSettings: .testTarget),
        .testTarget(name: "AuthFoundationTests",
                    dependencies: ["AuthFoundation", "TestCommon"],
                    resources: [
                        .copy("MockResponses"),
                        .copy("ConfigResources"),
                    ],
                    swiftSettings: .testTarget),
        .testTarget(name: "OAuth2AuthTests",
                    dependencies: ["OAuth2Auth", "TestCommon"],
                    resources: [ .copy("MockResponses") ],
                    swiftSettings: .testTarget),
        .testTarget(name: "OktaDirectAuthTests",
                    dependencies: ["OktaDirectAuth", "TestCommon"],
                    resources: [ .copy("MockResponses") ],
                    swiftSettings: .testTarget),
        .testTarget(name: "OktaIdxAuthTests",
                    dependencies: ["OktaIdxAuth", "TestCommon"],
                    resources: [.copy("MockResponses")],
                    swiftSettings: .testTarget),
    ],
    swiftLanguageModes: [.v5, .v6]
)

// Ensure the `TestScoping` feature is available when builds are made with older versions of Swift.
// This is included by default within Swift 6.1, or Xcode 16.3+, so this allows these test features
// to be backported to older compiler versions.
#if swift(<6.1)
package.dependencies.append(.package(url: "https://github.com/apple/swift-testing", from: "6.1.1"))
for target in package.targets {
    if target.name.contains(/Test/) {
        target.dependencies.append(.product(name: "Testing", package: "swift-testing"))
    }
}
#endif

#if canImport(AuthenticationServices) && canImport(UIKit) || canImport(AppKit)
package.targets.append(contentsOf: [
    .target(name: "BrowserSignin",
            dependencies: [
                .target(name: "OAuth2Auth")
            ],
            resources: [.process("Resources")],
            swiftSettings: .libraryTarget),
    .testTarget(name: "BrowserSigninTests",
                dependencies: ["BrowserSignin", "TestCommon"],
                resources: [ .copy("MockResponses") ],
                swiftSettings: .testTarget)
])
package.products.append(
    .library(name: "BrowserSignin", targets: ["BrowserSignin"])
)
#endif
