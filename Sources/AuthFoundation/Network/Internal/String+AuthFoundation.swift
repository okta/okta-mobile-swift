//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
    #if os(iOS)
        return "iOS"
    #elseif os(watchOS)
        return "watchOS"
    #elseif os(tvOS)
        return "tvOS"
    #elseif os(visionOS)
        return "visionOS"
    #elseif os(macOS)
        return "macOS"
    #elseif os(Linux)
        return "linux"
    #endif
}()

private let systemVersion: String = {
    #if os(iOS) || os(tvOS) || os(visionOS)
        return UIDevice.current.systemVersion
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
public final class SDKVersion: Sendable {
    /// The name of this library component.
    public let name: String
    
    /// The version number string of this library component.
    public let version: String
    
    public init(sdk name: String, version: String) {
        self.name = name
        self.version = version
    }
    
    /// The formatted display name for this individual library's information.
    public var displayName: String { "\(name)/\(version)" }
    
    /// The calculated user agent string that will be included in outgoing network requests.
    public private(set) static var userAgent: String = ""

    private static let lock = UnfairLock()
    fileprivate static var sdkVersions: [SDKVersion] = []
    
    /// Register a new SDK library component to be added to the ``userAgent`` value.
    /// > Note: SDK ``name`` values must be unique. If a duplicate SDK  version is already added, only the first registered SDK value will be applied.
    /// - Parameter sdk: SDK version to add.
    public static func register(sdk: SDKVersion) {
        lock.withLock {
            guard sdkVersions.filter({ $0.name == sdk.name }).isEmpty else {
                return
            }
            
            sdkVersions.append(sdk)
            
            let sdkVersions = SDKVersion.sdkVersions
                .sorted(by: { $0.name < $1.name })
                .map(\.displayName)
                .joined(separator: " ")
            userAgent = "\(sdkVersions) \(systemName)/\(systemVersion) Device/\(deviceModel)"
        }
    }
}

extension String {
    func expanded(using: [String: APIRequestArgument]) -> String {
        using.reduce(self) { (string, argument) in
            string.replacingOccurrences(of: "{\(argument.key)}", with: argument.value.stringValue)
        }
    }
}
