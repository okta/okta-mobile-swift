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

/// A struct representing a semver version.
public struct Version: RawRepresentable, CustomStringConvertible, ExpressibleByStringLiteral, Sendable, Codable, Equatable, Comparable, Hashable {
    /// Represents an individual component within a version.
    public enum Component: Sendable, Equatable {
        /// Numeric value component.
        case numeric(_ value: Int)
        
        /// String value component (e.g. "1.0.0-alpha")
        case string(_ value: String)
        
        fileprivate init(_ rawValue: String) {
            if let intValue = Int(rawValue) {
                self = .numeric(intValue)
            } else {
                self = .string(rawValue)
            }
        }

        fileprivate init(_ rawValue: Int) {
            precondition(rawValue >= 0, "Negative versioning is invalid.")
            self = .numeric(rawValue)
        }
    }
    
    /// Value used when a version number cannot be parsed, or does not exist.
    public static let unknown = Version("unknown")
    
    /// Current operating system version.
    public static let operatingSystem = Version(ProcessInfo.processInfo.operatingSystemVersion)

    /// Initialize using a string literal.
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    /// Initialize using a string.
    public init(_ value: String) {
        self.rawValue = value
        self.components = value
            .components(separatedBy: Self.Separator)
            .map({ Component($0) })
    }
    
    /// Initialize using the given optional raw string value.
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    /// Initializes a Version using a list of integer values.
    public init(_ values: Int...) {
        precondition(values.allSatisfy({ $0 >= 0 }), "Negative versioning is invalid.")
        self.rawValue = values.map({ String($0) }).joined(separator: ".")
        self.components = values.map({ .numeric($0) })
    }
    
    /// Initializes a Version using the Foundation `OperatingSystemVersion` type.
    public init(_ version: OperatingSystemVersion) {
        self.init(version.majorVersion, version.minorVersion, version.patchVersion)
    }
    
    @_documentation(visibility: private)
    public static func < (lhs: Version, rhs: Version) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for index in 0..<maxCount {
            let lhsVersion = lhs.version(at: index) ?? 0
            let rhsVersion = rhs.version(at: index) ?? 0
            
            if lhsVersion == rhsVersion {
                continue
            }
            return lhsVersion < rhsVersion
        }
        return true
    }
    
    /// Raw value of the original version string.
    public let rawValue: String
    
    /// The string representation of the version.
    public var description: String {
        rawValue
    }
        
    /// The major version.
    @inlinable public var major: Int {
        version(at: 0) ?? 0
    }

    /// The minor version.
    @inlinable public var minor: Int {
        version(at: 1) ?? 0
    }

    /// The patch version.
    @inlinable public var patch: Int {
        version(at: 2) ?? 0
    }
    
    /// Individual components of the version string.
    public let components: [Component]

    /// Return the given version component.
    @inlinable
    public func version(at index: Int) -> Component? {
        components.count > index ? components[index] : nil
    }
    
    /// Return the given version component as an integer.
    @inlinable
    public func version(at index: Int) -> Int? {
        guard case let .numeric(value) = version(at: index) else {
            return nil
        }

        return value
    }

    private static let Separator = CharacterSet(charactersIn: ".-/")
}
