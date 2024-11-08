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
import OktaConcurrency

#if canImport(UIKit)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

/// Utility class that allows SDK components to register their name and version for use in HTTP User-Agent values.
///
/// The Okta Client SDK consists of multiple libraries, each of which may or may not be used within the same application, or at the same time. To allow version information to be sustainably managed, this class can be used to centralize the registration of these SDK versions to report just the components used within an application.
@HasLock
public final class UserAgent: CustomStringConvertible, Sendable {
    /// Information about the running application.
    @Synchronized
    public var application: TargetInformation? {
        didSet {
            _description = generateUserAgent()
        }
    }
    
    /// Information about the libraries used within the application.
    @Synchronized
    public private(set) var libraries: [TargetInformation]
    
    /// Controls whether detailed anonymous analytics metrics should be included.
    @Synchronized(value: false)
    public var shouldOptOut: Bool
    
    let device: DeviceInformation
    
    public static let shared = UserAgent()
    
    public convenience init() {
        self.init(device: .current)
    }
    
    init(device: DeviceInformation) {
        self.device = device
        _application = nil
        _libraries = []
        _description = ""
        _description = generateUserAgent()
    }
    
    /// The calculated user agent string that will be included in outgoing network requests.
    @Synchronized
    public private(set) var description: String
    
    /// Register a new library component to be added to the ``userAgent`` value.
    /// > Note: SDK ``name`` values must be unique. If a duplicate SDK  version is already added, only the first registered SDK value will be applied.
    /// - Parameter sdk: SDK version to add.
    public static func register(target: TargetInformation) {
        shared.register(target: target)
    }
    
    private func generateUserAgent() -> String {
        var components: [String] = [
            device.description
        ]
        
        if let app = _application {
            components.append("Client \(app)")
        }
        
        components.append(contentsOf: _libraries
            .sorted(by: { $0.name < $1.name })
            .map(\.description))
        
        return components.joined(separator: " ")
    }
    
    func register(target: TargetInformation) {
        withLock {
            guard !_libraries.contains(target) else {
                return
            }
            _libraries.append(target)
            _description = generateUserAgent()
        }
    }
}




//private func deviceModel() -> String {
//#if canImport(Darwin)
//    var size: Int = 0
//    sysctlbyname("hw.model", nil, &size, nil, 0)
//    var machine = [CChar](repeating: 0, count: size)
//    sysctlbyname("hw.model", &machine, &size, nil, 0)
//    let machineName = String(cString: &machine)
//    print("HW model: \(machineName)")
//#else
//    var system = utsname()
//    uname(&system)
//    let sysname = withUnsafePointer(to: &system.sysname.0) { ptr in
//        return String(cString: ptr)
//    }
//
//    let model = withUnsafePointer(to: &system.machine.0) { ptr in
//        return String(cString: ptr)
//    }
//
//    let nodename = withUnsafePointer(to: &system.nodename.0) { ptr in
//        return String(cString: ptr)
//    }
//
//    let release = withUnsafePointer(to: &system.release.0) { ptr in
//        return String(cString: ptr)
//    }
//
//    let sysname = withUnsafePointer(to: &system.sysname.0) { ptr in
//        return String(cString: ptr)
//    }
//
//    let version = withUnsafePointer(to: &system.version.0) { ptr in
//        return String(cString: ptr)
//    }
//    
//    print("model: \(model)")
//    print("nodename: \(nodename)")
//    print("release: \(release)")
//    print("sysname: \(sysname)")
//    print("version: \(version)")
//    
//    var size: Int = 0
//    sysctlbyname("hw.model", nil, &size, nil, 0)
//    var machine = [CChar](repeating: 0, count: size)
//    sysctlbyname("hw.model", &machine, &size, nil, 0)
//    let machineName = String(cString: &machine)
//    print("HW model: \(machineName)")
//    
//    return model
//    #endif
//}
//
//private let systemName: String = {
//    #if os(iOS)
//        return "iOS"
//    #elseif os(watchOS)
//        return "watchOS"
//    #elseif os(tvOS)
//        return "tvOS"
//    #elseif os(visionOS)
//        return "visionOS"
//    #elseif os(macOS)
//        return "macOS"
//    #elseif os(Linux)
//        return "linux"
//    #endif
//}()
//
//private let systemVersion: String = {
//    #if os(iOS) || os(tvOS) || os(visionOS)
//        return UIDevice.current.systemVersion
//    #elseif os(watchOS)
//        return WKInterfaceDevice.current().systemVersion
//    #else
//        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
//        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
//    #endif
//}()
