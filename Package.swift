// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

#if canImport(Darwin)
let includePrivacyManifest = true
#else
let includePrivacyManifest = false
#endif

func exclude(_ resources: [String] = []) -> [String] {
    guard !includePrivacyManifest else {
        return resources
    }

    return resources + ["PrivacyInfo.xcprivacy"]
}

func include(_ resources: PackageDescription.Resource...) -> [PackageDescription.Resource]? {
    guard !includePrivacyManifest else {
        return Array(resources)
    }

    var result = Array(resources)
    result.append(.copy("PrivacyInfo.xcprivacy"))
    return result
}

var package = Package(
    name: "OktaClient",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v7),
        .visionOS(.v1),
        .macOS(.v10_15),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "AuthFoundation", targets: ["AuthFoundation"]),
        .library(name: "OktaOAuth2", targets: ["OktaOAuth2"]),
        .library(name: "OktaDirectAuth", targets: ["OktaDirectAuth"]),
        .library(name: "WebAuthenticationUI", targets: ["WebAuthenticationUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease")
    ],
    targets: [
        // Macros
        .macro(name: "_OktaClientMacros",
               dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
               ],
               path: "Sources/OktaClientMacros/Implementation"),
        .testTarget(name: "OktaClientMacrosTests",
                    dependencies: [
                        .target(name: "OktaClientMacros"),
                        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                    ]),
        .target(name: "OktaClientMacros",
                dependencies: [
                    "_OktaClientMacros",
                    .target(name: "OktaConcurrency"),
                ],
                path: "Sources/OktaClientMacros/Interface"),

        // Concurrency & locking
        .target(name: "OktaConcurrency",
                exclude: exclude(),
                resources: include()),
        .testTarget(name: "OktaConcurrencyTests",
                    dependencies: [
                        .target(name: "OktaConcurrency"),
                        .target(name: "TestCommon")
                    ]),

        // Common test utilities
        .target(name: "TestCommon",
                path: "Tests/TestCommon"),

        // Keychain
        .target(name: "Keychain",
                dependencies: [
                    .target(name: "OktaConcurrency"),
                    .target(name: "OktaClientMacros")
                ],
                exclude: exclude(),
                resources: include()),
        .target(name: "KeychainTestCommon",
                dependencies: [
                    .target(name: "Keychain")
                ],
                path: "Tests/KeychainTestCommon"),
        .testTarget(name: "KeychainTests",
                    dependencies: [
                        .target(name: "Keychain"),
                        .target(name: "KeychainTestCommon"),
                        .target(name: "TestCommon")
                    ]),

        // Common types
        .target(name: "OktaUtilities",
                dependencies: [
                    .target(name: "OktaConcurrency"),
                    .target(name: "OktaClientMacros")
                ],
                exclude: exclude(),
                resources: include()),
        .testTarget(name: "OktaUtilitiesTests",
                    dependencies: [
                        .target(name: "OktaUtilities"),
                        .target(name: "OktaConcurrency"),
                        .target(name: "OktaClientMacros"),
                        .target(name: "TestCommon")
                    ]),
        
//        .target(name: "AuthFoundationTestCommon",
//                dependencies: ["AuthFoundation"],
//                path: "Tests/AuthFoundationTestCommon"),

        // Abstract API Client
        .target(name: "APIClient",
                dependencies: [
                    .target(name: "OktaUtilities"),
                ],
                exclude: exclude(),
                resources: include()),
        .testTarget(name: "APIClientTests",
                    dependencies: [
                        .target(name: "APIClient"),
                        .target(name: "JWT"),
                        .target(name: "OktaConcurrency"),
                        .target(name: "APIClientTestCommon"),
                        .target(name: "TestCommon")
                    ]),
        .target(name: "APIClientTestCommon",
                dependencies: [
                    .target(name: "APIClient"),
                    .target(name: "JWT")
                ],
                path: "Tests/APIClientTestCommon",
                resources: [.process("MockResponses")]),

        // JSON & JWT
        .target(name: "JWT",
                dependencies: [
                    .target(name: "OktaUtilities"),
                    .target(name: "OktaConcurrency"),
                    .target(name: "APIClient")
                ],
                exclude: exclude(),
                resources: include(.process("Resources"))),
        .testTarget(name: "JWTTests",
                    dependencies: [
                        .target(name: "OktaConcurrency"),
                        .target(name: "OktaUtilities"),
                        .target(name: "JWT"),
                        .target(name: "TestCommon"),
                        .target(name: "APIClientTestCommon")
                    ],
                    resources: [ .process("MockResponses") ]),

        // AuthFoundation
        .target(name: "AuthFoundation",
                dependencies: [
                    "_OktaClientMacros",
                    .target(name: "OktaUtilities"),
                    .target(name: "OktaConcurrency"),
                    .target(name: "Keychain"),
                    .target(name: "APIClient"),
                    .target(name: "JWT"),
                ],
                exclude: exclude(),
                resources: include(.process("Resources"))),
        .target(name: "AuthFoundationTestCommon",
                dependencies: [
                    .target(name: "AuthFoundation"),
                    .target(name: "APIClientTestCommon")
                ],
                path: "Tests/AuthFoundationTestCommon"),
        .testTarget(name: "AuthFoundationTests",
                    dependencies: [
                        .target(name: "JWT"),
                        .target(name: "AuthFoundation"),
                        .target(name: "TestCommon"),
                        .target(name: "KeychainTestCommon"),
                        .target(name: "APIClientTestCommon"),
                        .target(name: "AuthFoundationTestCommon"),
                    ],
                    resources: [ .process("MockResponses") ]),

        // OktaOAuth2
        .target(name: "OktaOAuth2",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                exclude: exclude(),
                resources: include(.process("Resources"))),
        .testTarget(name: "OktaOAuth2Tests",
                    dependencies: [
                        .target(name: "OktaOAuth2"),
                        .target(name: "AuthFoundation"),
                        .target(name: "TestCommon"),
                        .target(name: "KeychainTestCommon"),
                        .target(name: "APIClientTestCommon"),
                        .target(name: "AuthFoundationTestCommon"),
                    ],
                    resources: [ .process("MockResponses") ]),

        // OktaDirectAuth
        .target(name: "OktaDirectAuth",
                dependencies: [
                    .target(name: "AuthFoundation")
                ],
                exclude: exclude(),
                resources: include(.process("Resources"))),
        .testTarget(name: "OktaDirectAuthTests",
                    dependencies: [
                        .target(name: "APIClient"),
                        .target(name: "JWT"),
                        .target(name: "OktaDirectAuth"),
                        .target(name: "AuthFoundation"),
                        .target(name: "TestCommon"),
                        .target(name: "KeychainTestCommon"),
                        .target(name: "APIClientTestCommon"),
                        .target(name: "AuthFoundationTestCommon"),
                    ],
                    resources: [ .process("MockResponses") ]),

        // WebAuthenticationUI
        .target(name: "WebAuthenticationUI",
                dependencies: [
                    .target(name: "OktaOAuth2")
                ],
                exclude: exclude(),
                resources: include(.process("Resources"))),
        .testTarget(name: "WebAuthenticationUITests",
                    dependencies: [
                    .target(name: "WebAuthenticationUI"),
                    .target(name: "OktaOAuth2"),
                    .target(name: "AuthFoundation"),
                    .target(name: "TestCommon"),
                    .target(name: "KeychainTestCommon"),
                    .target(name: "APIClientTestCommon"),
                    .target(name: "AuthFoundationTestCommon"),
                ],
                resources: [ .process("MockResponses") ]),
    ],
    swiftLanguageVersions: [.v5]
)

#if compiler(>=6)
for target in package.targets where target.type != .system && target.type != .test {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: [
        .enableExperimentalFeature("StrictConcurrency"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InferSendableFromCaptures"),
    ])
}
#endif
