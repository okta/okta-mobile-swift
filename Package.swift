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
        .library(name: "AuthFoundation", targets: ["CommonSupport", "AuthFoundation"]),
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
        .target(name: "AuthFoundation",
                dependencies: ["CommonSupport"],
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
