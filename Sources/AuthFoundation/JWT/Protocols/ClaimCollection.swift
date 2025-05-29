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

/// Defines a type of collection which can be
@_documentation(visibility: internal)
public protocol ClaimCollectionContainer: Sendable {
    associatedtype Element: ClaimConvertable & APIRequestArgument
    associatedtype RawValue
    
    var array: [Element] { get set }
    var isNil: Bool { get }
    
    init(container elements: [Element]?)
}

@_documentation(visibility: internal)
extension Array: ClaimCollectionContainer where Element: ClaimConvertable & APIRequestArgument {
    public typealias RawValue = String
    
    public var array: [Element] {
        get { self }
        set { self = newValue }
    }
    
    public var isNil: Bool { false }
    
    public init(container elements: [Element]?) {
        self.init(elements ?? [])
    }
}

@_documentation(visibility: internal)
extension Optional: ClaimCollectionContainer where Wrapped: ClaimCollectionContainer {
    public typealias Element = Wrapped.Element
    public typealias RawValue = String?

    public var array: [Element] {
        get {
            switch self {
            case .none:
                return []
            case .some(let wrapped):
                return wrapped.array
            }
        }
        
        set {
            if let newValue = newValue as? Wrapped {
                self = .some(newValue)
            } else {
                self = .none
            }
        }
    }
    
    public var isNil: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }
    
    public init(container elements: [Element]?) {
        if let elements = elements {
            self = .some(Wrapped(container: elements))
        } else {
            self = .none
        }
    }
}

/// Represents a type which can contain a whitespace-separated array of string values.
///
/// This is used in a variety of function arguments to simplify the processing of `String` and `[String]` values.
@_documentation(visibility: internal)
public protocol WhitespaceSeparated {
    var whitespaceSeparated: [String] { get }
}

@_documentation(visibility: internal)
extension String: WhitespaceSeparated {
    @inlinable public var whitespaceSeparated: [String] {
        components(separatedBy: .whitespaces)
    }
}

@_documentation(visibility: internal)
extension Array: WhitespaceSeparated where Element == String {
    @inlinable public var whitespaceSeparated: [String] {
        self
    }
}

/// Indicates a special type of claim whose value is interchangable between a whitespace-separated value, or an array of values.
///
/// This is used to simplify interactions with Claim values whose raw representation is the claim's string value, separated by whitespace. This enables the conversion between the string representation, as sent to/received from the server, and the array of claims which it represents.
///
/// The ``rawValue`` of the collection returns the whitespace-separated string representation of the value this wrapper contains, which can be accessed using the projected value of the property. For example:
///
/// ```
/// config.scope.append("profile")
/// print(config.$scope.rawValue)
/// ```
@propertyWrapper
public struct ClaimCollection<Container: ClaimCollectionContainer>: Sendable {
    /// The array representation of the claims in this list.
    public var wrappedValue: Container
    
    /// Provides access to the property wrapper.
    public var projectedValue: Self { self }
    
    /// Initializer using the array representation of this value.
    /// - Parameter wrappedValue: Array of claim values.
    public init(wrappedValue: Container) {
        self.wrappedValue = wrappedValue
    }
}

extension ClaimCollection: APIRequestArgument where Container.RawValue == String {
    @_documentation(visibility: internal)
    public var stringValue: Container.RawValue {
        rawValue
    }
}

extension ClaimCollection: Codable where Container: Codable {
    @_documentation(visibility: internal)
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(Container.self)
    }

    @_documentation(visibility: internal)
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension ClaimCollection: ExpressibleByArrayLiteral {
    /// Initializer using an array literal representation of values.
    ///
    /// This simplifies the creation of a claim list wrapper from a raw array literal of values.
    /// - Parameter elements: List of claim values.
    public init(arrayLiteral elements: Container.Element ...) {
        self.wrappedValue = Container(container: elements)
    }
}

@_documentation(visibility: internal)
extension ClaimCollection: ExpressibleByNilLiteral where Container: ExpressibleByNilLiteral {
    @_documentation(visibility: internal)
    public init(nilLiteral: ()) {
        self.wrappedValue = .init(container: nil)
    }
    
    @_documentation(visibility: internal)
    public var isNil: Bool {
        wrappedValue.isNil
    }
}

extension ClaimCollection: RawRepresentable {
    public typealias RawValue = Container.RawValue
    
    /// The whitespace-separated string representation of the values in this claim list.
    ///
    /// It is recommended that this property be used when representing this list of claims when sending the value to a server.
    public var rawValue: RawValue {
        // swiftlint:disable force_cast
        if wrappedValue.isNil {
            return (nil as String?) as! RawValue
        }
        
        return wrappedValue
            .array
            .compactMap { $0.stringValue }
            .joined(separator: " ") as! RawValue
        // swiftlint:enable force_cast
    }
    
    /// Initializer accepting a whitespace-separated string representation of the value.
    /// - Parameter value: Whitespace-separated string.
    public init(wrappedValue value: String) {
        self.wrappedValue = Container(container: value.whitespaceSeparated.compactMap(Container.Element.convert(from:)))
    }
}

extension ClaimCollection where Container.RawValue == String? {
    public init(rawValue value: String?) {
        if let value = value {
            self.wrappedValue = Container(container: value.whitespaceSeparated.compactMap(Container.Element.convert(from:)))
        } else {
            self.wrappedValue = .init(container: nil)
        }
    }
}

extension ClaimCollection where Container.RawValue == String {
    public init(rawValue value: String) {
        self.init(wrappedValue: value)
    }
}

extension ClaimCollection {
    public init(rawValue: Container.RawValue) {
        if Container.self is (any ExpressibleByNilLiteral) {
            // swiftlint:disable:next force_unwrapping
            self.wrappedValue = Optional<Container>.none!
        } else {
            self.wrappedValue = Container(container: [])
        }
    }
}

extension ClaimCollection: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(wrappedValue: value)
    }
}

extension ClaimCollection: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(wrappedValue: value)
    }
}

extension ClaimCollection: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String) {
        self.init(wrappedValue: value)
    }
}

extension ClaimCollection: Hashable where Container.Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue.array)
    }
}

extension ClaimCollection: Equatable where Container.Element: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue.array == rhs.wrappedValue.array
    }
}
