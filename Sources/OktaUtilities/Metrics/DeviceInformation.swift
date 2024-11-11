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

/// Represents the information for a given device.
public struct DeviceInformation: CustomStringConvertible, Equatable, Codable, Sendable {
    /// The kernel name for the platform.
    public let kernelName: String?
    
    /// The CPU architecture this code is compiled and running on.
    public let architecture: String?
    
    /// The model of the device, if available.
    public let deviceModel: String?
    
    /// The general platform for this device.
    public let platform: SystemPlatform
    
    /// The version of the current system.
    public let version: Version
    
    /// Information about the current device.
    public static let current = DeviceInformation()
    
    public var description: String {
        [languageString, kernelString]
            .compactMap({ $0 })
            .joined(separator: " ")
    }
    
    private var kernelString: String? {
        let result = "Kernel".with(suffix: kernelName,
                                   architecture)
        guard result != "Kernel" else {
            return nil
        }
        return result
    }
    
    private var languageString: String {
        "Language".with(suffix: "Swift",
                        platform.with(suffix: version),
                        deviceModel)
    }
    
    init(architecture: String? = Self.cpuArchitecture,
         kernelName: String? = Self.kernelName,
         deviceModel: String? = Self.deviceModel,
         platform: SystemPlatform = .current,
         version: Version = .operatingSystem)
    {
        self.architecture = architecture
        self.kernelName = kernelName
        self.deviceModel = deviceModel
        self.platform = platform
        self.version = version
    }

    private static var kernelName: String? {
        var system: utsname = utsname()
        guard uname(&system) == 0 else {
            return nil
        }

        let sysname = withUnsafePointer(to: &system.sysname.0) { ptr in
            return String(cString: ptr)
        }
        
        return sysname
    }

#if canImport(Darwin)
    private static var cpuArchitecture: String? {
        Self.hwValue(name: "machine")
    }

    private static var deviceModel: String? {
        Self.hwValue(name: "model")
    }

    private static func hwValue(name: String) -> String? {
        var size: Int = 0
        sysctlbyname("hw.\(name)", nil, &size, nil, 0)
        var value = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.\(name)", &value, &size, nil, 0)
        return String(cString: &value)
    }

#else
    private static var cpuArchitecture: String? {
        var system: utsname = utsname()
        guard uname(&system) == 0 else {
            return nil
        }

        let value = withUnsafePointer(to: &system.machine.0) { ptr in
            return String(cString: ptr)
        }
        
        return value
    }

    private static var deviceModel: String? {
        nil
    }
    #endif
}
