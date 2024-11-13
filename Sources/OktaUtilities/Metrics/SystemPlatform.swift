//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

/// Defines the various system platforms the code may run on.
public struct SystemPlatform: RawRepresentable, CustomStringConvertible, ExpressibleByStringLiteral, Equatable, Hashable, Codable, Sendable {
    /// The name of the platform.
    public let rawValue: String

    /// The name of the platform.
    public var description: String { rawValue }
    
    /// Create a platform.
    @inlinable
    public init(rawValue name: String) {
        self.rawValue = name
    }

    /// Create a platform.
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public static let macOS: SystemPlatform = "macOS"
    public static let macCatalyst: SystemPlatform = "macCatalyst"
    public static let iOS: SystemPlatform = "iOS"
    public static let tvOS: SystemPlatform = "tvOS"
    public static let watchOS: SystemPlatform = "watchOS"
    public static let visionOS: SystemPlatform = "visionOS"
    public static let linux: SystemPlatform = "Linux"
    public static let android: SystemPlatform = "Android"
    public static let windows: SystemPlatform = "Windows"
    public static let wasi: SystemPlatform = "WASI"
    public static let openbsd: SystemPlatform = "OpenBSD"
    public static let freebsd: SystemPlatform = "FreeBSD"
    public static let other: SystemPlatform = "Other"

    /// The current platform this SDK is running within.
    public static let current: SystemPlatform = {
#if targetEnvironment(macCatalyst)
        return .macCatalyst
#elseif os(iOS)
        return .iOS
#elseif os(watchOS)
        return .watchOS
#elseif os(tvOS)
        return .tvOS
#elseif os(visionOS)
        return .visionOS
#elseif os(macOS)
        return .macOS
#elseif os(WASI)
        return .wasi
#elseif os(Linux)
        return .linux
#elseif os(FreeBSD)
        return .freebsd
#elseif os(OpenBSD)
        return .openbsd
#elseif os(Windows)
        return .windows
#else
        return .other
#endif
    }()
    
    @_documentation(visibility: private)
    public static func == (lhs: SystemPlatform, rhs: SystemPlatform) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }
    
    @_documentation(visibility: private)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.lowercased())
    }
}
