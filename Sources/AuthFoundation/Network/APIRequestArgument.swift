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

/// Defines an argument to an ``APIRequest``. Used within ``APIRequest/headers-8ieky`` and ``APIRequest/query-730ld``.
///
/// The following types conform to this protocol:
/// - String
/// - Int
/// - Double
/// - Bool
/// - UInt
/// - Int8
/// - UInt8
/// - Int16
/// - UInt16
/// - Int32
/// - UInt32
/// - Int64
/// - UInt64
/// - Float
/// - NSString
/// - NSNumber
public protocol APIRequestArgument: Sendable {
    /// The string representation of this request argument.
    var stringValue: String { get }
}

extension Dictionary<String, APIRequestArgument> {
    @_documentation(visibility: private)
    public var stringComponents: [String: String] {
        mapValues { $0.stringValue }
    }
}

extension APIRequestArgument where Self: RawRepresentable, Self.RawValue.Type == String.Type {
    @_documentation(visibility: private)
    public var stringValue: String {
        rawValue
    }
}

extension String: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { self }
}

extension Int: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Double: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Bool: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension UInt: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Int8: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension UInt8: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Int16: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension UInt16: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Int32: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension UInt32: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Int64: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension UInt64: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension Float: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

extension NSString: APIRequestArgument {
    @_documentation(visibility: private)
    public var stringValue: String { "\(self)" }
}

@_documentation(visibility: private)
extension NSNumber: APIRequestArgument {}

@_documentation(visibility: private)
extension JWT: APIRequestArgument {}

@_documentation(visibility: private)
extension GrantType: APIRequestArgument {}

@_documentation(visibility: private)
extension Array: APIRequestArgument where Element: APIRequestArgument {
    public var stringValue: String {
        map(\.stringValue)
            .joined(separator: " ")
    }
}

@_documentation(visibility: private)
extension Token.Kind: APIRequestArgument {}

@_documentation(visibility: private)
extension URL: APIRequestArgument {
    public var stringValue: String { absoluteString }
}
