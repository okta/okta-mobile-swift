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

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

private let deviceModel: String = {
    var system = utsname()
    uname(&system)
    let model = withUnsafePointer(to: &system.machine.0) { ptr in
        return String(cString: ptr)
    }
    return model
}()

private let systemName: String = {
    #if (swift(>=5.10) && os(visionOS))
        return "visionOS"
    #elseif os(iOS)
        return "iOS"
    #elseif os(watchOS)
        return "watchOS"
    #elseif os(tvOS)
        return "tvOS"
    #elseif os(macOS)
        return "macOS"
    #elseif os(Linux)
        return "linux"
    #endif
}()

private let systemVersion: String = {
    #if os(iOS) || os(tvOS) || (swift(>=5.10) && os(visionOS))
    return MainActor.assumeIsolated {
        UIDevice.current.systemVersion
    }
    #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
    #else
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    #endif
}()

/// Utility class that allows SDK components to register their name and version for use in HTTP User-Agent values.
///
/// The Okta Client SDK consists of multiple libraries, each of which may or may not be used within the same application, or at the same time. To allow version information to be sustainably managed, this class can be used to centralize the registration of these SDK versions to report just the components used within an application.
public struct SDKVersion: Sendable {
    /// The name of this library component.
    public let name: Name

    /// The version number string of this library component.
    public let version: String

    public init(sdk name: Name, version: String) {
        self.name = name
        self.version = version
    }

    /// The formatted display name for this individual library's information.
    public var displayName: String { "\(name)/\(version)" }

    /// The calculated user agent string that will be included in outgoing network requests.
    public static var userAgent: String {
        lock.withLock {
            _userAgent
        }
    }

    /// Register a new SDK library component to be added to the ``userAgent`` value.
    /// > Note: SDK ``name`` values must be unique. If a duplicate SDK  version is already added, only the first registered SDK value will be applied.
    /// - Parameter sdk: SDK version to add.
    public static func register(sdk: SDKVersion) {
        lock.withLock {
            guard _sdkVersions.filter({ $0.name == sdk.name }).isEmpty else {
                return
            }

            _sdkVersions.append(sdk)

            let sdkVersionString = _sdkVersions
                .sorted(by: { $0.name.rawValue < $1.name.rawValue })
                .map(\.displayName)
                .joined(separator: " ")
            _userAgent = "\(sdkVersionString) \(systemName)/\(systemVersion) Device/\(deviceModel)"
        }
    }
    
    /// Returns the version information for the given SDK.
    /// - Parameter sdkName: SDK name to search for.
    /// - Returns: Version information for the given SDK name.
    public static func version(for sdkName: Name) -> SDKVersion? {
        lock.withLock {
            _sdkVersions.first(where: { $0.name == sdkName })
        }
    }

    // MARK: Private properties / methods
    private static let lock = Lock()
    nonisolated(unsafe) private static var _sdkVersions: [SDKVersion] = []
    nonisolated(unsafe) private static var _userAgent: String = ""
}
