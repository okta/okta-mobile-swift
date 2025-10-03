//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if !COCOAPODS
import CommonSupport
#endif

public enum JSONError: Error, Sendable, Hashable, Equatable {
    case invalidUTF8String
    case invalidJSONValue
    case unsupportedRootValue
    
    public static func == (lhs: JSONError, rhs: JSONError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUTF8String, .invalidUTF8String):
            return true
        case (.invalidJSONValue, .invalidJSONValue):
            return true
        case (.unsupportedRootValue, .unsupportedRootValue):
            return true
        default:
            return false
        }
    }
}

/// Mutable value type representing JSON and its contents in a type-safe and performant way.
///
/// JSON data may be imported from multiple sources, be it Data, String, an alread-parsed JSON object consisting of `Any` values, or an object conforming to `Codable`. Transforming data between these states, and dealing with error conditions every time, can be cumbersome.
///
/// This also supports mutation of JSON values, including the ability to regenerate the resulting JSON string notation, while maintaining performance through the use of the "Copy on Write" pattern.
public struct JSON: Sendable, Codable, Hashable {
    private(set) var storage: CopyOnWrite<Storage>

    /// Indicates the current representation the JSON value is stored as.
    public var representation: Representation { storage.value.representation }
    
    /// Renders the JSON object as `Data`.
    public var data: Data {
        get throws {
            try storage.value.data
        }
    }

    /// Initializes a ``JSON`` object from a JSON-formatted string.
    ///
    /// ```swift
    /// let json = try JSON("""
    ///     {"key": "value"}
    /// """)
    /// ```
    /// - Parameter string: JSON-formatted string.
    public init(_ string: String) throws {
        self.storage = try CopyOnWrite(Storage(string))
    }

    /// Initializes a ``JSON`` object from a JSON-formatted `Data` value.
    public init(_ data: Data) throws {
        self.storage = try CopyOnWrite(Storage(data))
    }
    
    /// Initializes a ``JSON`` object from another JSON instance.
    /// - Parameter value: Other JSON object to copy.
    public init(_ value: JSON) {
        self.storage = CopyOnWrite(Storage(value.storage.value.value))
    }
    
    /// Initializes a ``JSON`` object from any object that conforms to `Codable`.
    ///
    /// This works by first encoding the object, and then attempting to decode it using a JSON decoder.
    /// - Parameter value: Value to decode into JSON.
    public init(_ value: any Codable) throws {
        self.storage = try CopyOnWrite(Storage(value))
    }
    
    /// Attempts to initialize a ``JSON`` object from an `Any` value that consists of objects capable of being parsed by `JSONSerialization`.
    /// - Parameter value: Value to attempt to encode as JSON.
    public init(_ value: Any) throws {
        self.storage = try CopyOnWrite(Storage(value))
    }
    
    /// Initializes a ``JSON`` object from internal types known to be supported by JSON.
    /// - Parameter value: Value to attempt to encode as JSON.
    public init(_ value: some JSONRootValue) {
        self.storage = CopyOnWrite(Storage(value))
    }
    
    /// Initializes a ``JSON`` object from a valid ``JSON/Value`` type.
    /// - Parameter value: JSON value to use as the root value.
    public init(_ value: Value) {
        self.storage = CopyOnWrite(Storage(value))
    }
    
    /// Initializes a ``JSON`` object from within an existing `Decoder` `init(from:)` function.
    ///
    /// This initializer is useful if a JSON value is being wrapped by a parent object that conforms to `Codable`, or if a subset of an object's properties is a JSON string.
    /// - Parameter decoder: The decoder object.
    public init(from decoder: any Decoder) throws {
        self.storage = CopyOnWrite(Storage(try Value(from: decoder)))
    }
    
    public func encode(to encoder: any Encoder) throws {
        try storage.value.value.encode(to: encoder)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage.value.value)
    }
    
    /// Encodes the current ``JSON`` values as a JSON data value.
    ///
    /// > Note: This updates the object's ``representation`` storage for performance reasons, simplifying subsequent accesses to the same data value.
    /// - Returns: JSON-formatted representation.
    @discardableResult
    public mutating func encode() throws -> Data {
        return try storage.modify { storage in
            try storage.render()
        }
    }

    /// Encodes the current ``JSON`` values as a JSON data value `String`.
    ///
    /// > Note: This updates the object's ``representation`` storage for performance reasons, simplifying subsequent accesses to the same data value.
    /// - Returns: JSON-formatted string representation.
    public mutating func encode() throws -> String {
        guard let result = String(data: try self.encode(), encoding: .utf8) else {
            throw JSONError.invalidUTF8String
        }
        return result
    }
    
    /// The ``JSON/Value`` that constitutes the root of this JSON object.
    public var value: Value {
        get {
            self.storage.value.value
        }
        mutating set {
            storage.modify { storage in
                storage.value = newValue
            }
        }
    }

    public subscript(_ key: String) -> Value? {
        get {
            storage.value.value.object?[key] ?? .null
        }
        set {
            storage.modify { storageValue in
                if case var .object(dictionary) = storageValue.value {
                    dictionary[key] = newValue
                    storageValue.value = .object(dictionary)
                }
            }
        }
    }

    public subscript(_ key: Int) -> Value? {
        get {
            storage.value.value.array?[key] ?? .null
        }
        set {
            storage.modify { storageValue in
                if case var .array(array) = storageValue.value {
                    array[key] = newValue ?? .null
                    storageValue.value = .array(array)
                }
            }
        }
    }
}

extension JSON: Equatable {
    @inlinable
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        lhs.representation == rhs.representation
    }
}

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.value)
    }
}

extension JSON {
    @inlinable
    public static func + (lhs: JSON, rhs: JSON) -> JSON {
        JSON(lhs.value + rhs.value)
    }
    
    @inlinable
    public static func += (lhs: inout JSON, rhs: JSON) {
        lhs = lhs + rhs
    }
}

extension JSON.Value {
    @inlinable
    public static func + (lhs: JSON.Value, rhs: JSON.Value) -> JSON.Value {
        switch (lhs, rhs) {
        case (.object(let lhs), .object(let rhs)):
            return .object(lhs.merging(rhs, uniquingKeysWith: { (_, new) in new }))
        case (.array(let lhs), .array(let rhs)):
            return .array(lhs + rhs)
        case (.primitive(let lhs), .primitive(let rhs)):
            return .primitive(lhs + rhs)
        default:
            return lhs
        }
    }
    
    @inlinable
    public static func += (lhs: inout JSON.Value, rhs: JSON.Value) {
        lhs = lhs + rhs
    }
}

extension JSON.Primitive {
    @inlinable
    public static func + (lhs: JSON.Primitive, rhs: JSON.Primitive) -> JSON.Primitive {
        switch (lhs, rhs) {
        case (.string(let lhs), .string(let rhs)):
            return .string(lhs + rhs)
        case (.int(let lhs), .int(let rhs)):
            return .int(lhs + rhs)
        case (.double(let lhs), .double(let rhs)):
            return .double(lhs + rhs)
        default:
            return lhs
        }
    }
    
    @inlinable
    public static func += (lhs: inout JSON.Primitive, rhs: JSON.Primitive) {
        lhs = lhs + rhs
    }
}

extension JSON: JSONObjectRepresentable {
    @inlinable public var isNull: Bool {
        value == .null
    }

    @inlinable public var anyValue: (any Sendable)? {
        get { value.anyValue }
        set { value.anyValue = newValue }
    }
    
    @inlinable public var string: String? {
        get { value.string }
        set { value.string = newValue }
    }
    
    @inlinable public var int: Int? {
        get { value.int }
        set { value.int = newValue }
    }
    
    @inlinable public var double: Double? {
        get { value.double }
        set { value.double = newValue }
    }
    
    @inlinable public var bool: Bool? {
        get { value.bool }
        set { value.bool = newValue }
    }
    
    @inlinable public var array: [Value]? {
        get { value.array }
        set { value.array = newValue }
    }
    
    @inlinable public var object: [String: Value]? {
        get { value.object }
        set { value.object = newValue }
    }
}
