//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public enum JSONError: Error {
    case cannotDecode(value: (any Sendable)?)
    case invalidContentEncoding
    case objectExpected
    case arrayExpected
}

/// Efficiently represents ``JSON`` values, and exchanges between its String or Data representations.
///
/// JSON data may be imported from multiple sources, be it Data, a String, or an alread-parsed JSON object. Transforming data between these states, and dealing with error conditions every time, can be cumbersome. AnyJSON is a convenience wrapper class that allows underlying JSON to be lazily mapped between types as needed.
public final class AnyJSON {
    private enum Value: Sendable {
        case json(JSON)
        case string(String)
        case data(Data)
    }
    
    private let value: Value
    private let lock = Lock()
    nonisolated(unsafe) private var _stringValue: String?
    nonisolated(unsafe) private var _dataValue: Data?
    nonisolated(unsafe) private var _jsonValue: JSON?

    /// The string encoding of the JSON data.
    public var stringValue: String {
        if case let .string(string) = value {
            return string
        }

        return lock.withLock { getStringValue() }
    }
    
    /// The data encoding of the JSON value.
    public var dataValue: Data {
        if case let .data(data) = value {
            return data
        }

        return lock.withLock { getDataValue() }
    }
    
    /// The ``JSON`` representation of the JSON data.
    public var jsonValue: JSON {
        if case let .json(json) = value {
            return json
        }

        return lock.withLock { getJsonValue() }
    }

    private func getStringValue() -> String {
        if let result = _stringValue {
            return result
        }

        let result = String(data: getDataValue(), encoding: .utf8) ?? ""
        _stringValue = result
        return result
    }

    private func getDataValue() -> Data {
        if let result = _dataValue {
            return result
        }

        let result: Data
        valueBlock: switch value {
        case .json(let json):
            guard let anyValue = json.anyValue else {
                result = Data()
                break valueBlock
            }
            result = (try? JSONSerialization.data(withJSONObject: anyValue)) ?? Data()
        case .string(let string):
            result = string.data(using: .utf8) ?? Data()
        case .data(let data):
            result = data
        }

        _dataValue = result
        return result
    }

    private func getJsonValue() -> JSON {
        if let result = _jsonValue {
            return result
        }

        let result: JSON
        if case let .string(string) = value {
            result = (try? JSON(string)) ?? .null
        } else if case let .data(data) = value {
            result = (try? JSON(data)) ?? .null
        } else {
            result = .null
        }
        _jsonValue = result
        return result
    }

    /// Initializes the JSON data based on a string value.
    /// - Parameter string: JSON string.
    public init(_ string: String) {
        value = .string(string)
    }
    
    
    /// Initializes the JSON data based on a data value.
    /// - Parameter data: JSON data.
    public init(_ data: Data) {
        value = .data(data)
    }
    
    /// Initializes the JSON data based on a ``JSON`` value.
    /// - Parameter json: The ``JSON`` value.
    public init(_ json: JSON) {
        if case let .string(value) = json {
            self.value = .string(value)
        } else {
            value = .json(json)
        }
    }
}

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
extension AnyJSON: @unchecked Sendable {}
#else
extension AnyJSON: Sendable {}
#endif

/// Represent mixed JSON values as instances of `Any`. This is used to expose API response values to Swift native types where Swift enums are not supported.
public enum JSON: Sendable, Hashable, Equatable {
    /// String JSON key value.
    case string(String)

    /// Number JSON key value.
    case number(NSNumber)
    
    /// Boolean JSON key value.
    case bool(Bool)
    
    /// Object JSON key value, containing its own nested key/value pairs.
    indirect case object([String: JSON])

    /// Array JSON key value, containing its own nested JSON values.
    indirect case array([JSON])

    /// Null JSON key value.
    case null
    
    /// Initializes a JSON object from a variety of supported types.
    /// - Parameter value: Value to represent as a JSON stru ture.
    public init(_ value: (any Sendable)?) throws {
        guard let value = value
        else {
            self = .null
            return
        }

        try self.init(value)
    }

    @_documentation(visibility: internal)
    @inlinable
    public init(_ value: Any) throws {
        if let value = value as? any JSONRepresentable {
            self = value.json
        } else if let value = value as? String {
            self = .string(value)
        } else if let value = value as? NSNumber {
            self = .number(value)
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? [String: Any] {
            self = .object(try value.mapValues({ try JSON($0) }))
        } else if let value = value as? [Any] {
            self = .array(try value.map({ try JSON($0) }))
        } else {
            throw JSONError.cannotDecode(value: nil)
        }
    }

    /// Initializes a JSON object from its string representation.
    /// - Parameter value: The String value for a JSON object.
    public init(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw JSONError.invalidContentEncoding
        }
        try self.init(data)
    }
    
    /// Initializes a JSON object from its data representation.
    /// - Parameter value: The data value for a JSON object.
    public init(_ value: Data) throws {
        try self.init(try JSONSerialization.jsonObject(with: value))
    }
    
    /// Initializes a JSON object from an encodable object representation.
    /// - Parameter value: The object conforming to `Encodable` to convert to JSON.
    public init(_ value: some Encodable) throws {
        try self.init(try JSONEncoder().encode(value))
    }

    /// Returns the value as an instance of `Any`.
    public var anyValue: Any? {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return value
        case let .bool(value):
            return value
        case let .object(value):
            return value.reduce(into: [String: Any?]()) {
                $0[$1.key] = $1.value.anyValue
            }
        case let .array(value):
            return value.map { $0.anyValue }
        case .null:
            return nil
        }
    }

    /// Returns the array value at the given index, or `nil` if the object is not an array.
    public subscript(index: Int) -> JSON {
        get { (try? value(at: index)) ?? .null }
    }

    /// Returns the object value with the given key, or `nil` if this is not an object.
    public subscript(key: String) -> JSON {
        get { (try? value(forKey: key)) ?? .null }
    }
    
    @_documentation(visibility: internal)
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhsValue), .string(let rhsValue)):
            return lhsValue == rhsValue
        case (.number(let lhsValue), .number(let rhsValue)):
            return lhsValue == rhsValue
        case (.bool(let lhsValue), .bool(let rhsValue)):
            return lhsValue == rhsValue
        case (.object(let lhsValue), .object(let rhsValue)):
            return lhsValue == rhsValue
        case (.array(let lhsValue), .array(let rhsValue)):
            return lhsValue == rhsValue
        case (.null, .null):
            return true
        default:
            return false
        }
    }
}

extension JSON {
    /// Returns the specified value from a JSON array.
    /// - Parameter index: Index to return
    /// - Returns: JSON value at that array index.
    /// - Throws: ``JSONError/arrayExpected`` if the receiver is not an array.
    @inlinable
    public func value(at index: Int) throws -> JSON {
        guard case let .array(array) = self else {
            throw JSONError.arrayExpected
        }

        if array.indices.contains(index) {
            return array[index]
        } else {
            return .null
        }
    }
}

extension JSON {
    /// Returns the object value for the given key, if the receiver is an object.
    /// - Parameter key: Key to return the value for.
    /// - Returns: The old value, if any, that was at that key.
    /// - Throws: ``JSONError/objectExpected`` if the receiver is not an object.
    @inlinable
    public func value(forKey key: String) throws -> JSON {
        guard case let .object(dict) = self else {
            throw JSONError.objectExpected
        }

        return dict[key] ?? .null
    }
}

extension JSON: Codable {
    @_documentation(visibility: internal)
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .number(value as NSNumber)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value as NSNumber)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSON].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSON].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Invalid JSON value \(decoder.codingPath)"))
        }
    }
    
    @_documentation(visibility: internal)
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            if value.isFloatingPoint {
                try container.encode(value.doubleValue)
            } else {
                try container.encode(value.intValue)
            }
        case let .bool(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

fileprivate extension NSNumber {
    var isFloatingPoint: Bool {
        if strcmp(objCType, "f") == 0 ||
            strcmp(objCType, "d") == 0
        {
            return true
        }
        
        return false
    }
}

extension JSON: CustomStringConvertible, CustomDebugStringConvertible {
    @_documentation(visibility: internal)
    @inlinable public var description: String {
        _stringValue(debug: false)
    }

    @_documentation(visibility: internal)
    @inlinable public var debugDescription: String {
        _stringValue(debug: true)
    }

    @usableFromInline
    func _stringValue(debug: Bool) -> String {
        switch self {
        case .string(let str):
            return debug ? str.debugDescription : str
        case .number(let num):
            return debug ? num.debugDescription : num.description
        case .bool(let bool):
            return bool ? "true" : "false"
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            if debug {
                encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            } else {
                encoder.outputFormatting = [.sortedKeys]
            }

            // swiftlint:disable force_unwrapping
            // swiftlint:disable force_try
            return try! String(data: encoder.encode(self), encoding: .utf8)!
            // swiftlint:enable force_try
            // swiftlint:enable force_unwrapping
        }
    }
}

extension JSON: ExpressibleByStringLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByExtendedGraphemeClusterLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByUnicodeScalarLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByNilLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByFloatLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(floatLiteral value: Double) {
        self = .number(NSNumber(value: value))
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(NSNumber(value: value))
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    @_documentation(visibility: internal)
    @inlinable
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

/// Represents types that are interoperable or usable with JSON.
public protocol JSONRepresentable: Sendable {
    /// Returns the JSON representation for this object.
    var json: JSON { get }
}

extension JSON: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { self }
    }
}

extension String: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .string(self) }
    }
}

extension Int: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .number(NSNumber(value: self)) }
    }
}

extension Double: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .number(NSNumber(value: self)) }
    }
}

extension Float: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .number(NSNumber(value: self)) }
    }
}

extension Bool: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .bool(self) }
    }
}

extension Array: JSONRepresentable where Element: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .array(compactMap({ $0.json })) }
    }
}

extension Dictionary: JSONRepresentable where Key == String, Value: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .object(mapValues(\.json)) }
    }
}

extension Optional: JSONRepresentable where Wrapped: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get {
            switch self {
            case .none:
                return .null
            case .some(let wrapped):
                return wrapped.json
            }
        }
    }
}

extension NSNull: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { .null }
    }
}

extension RawRepresentable where RawValue == JSON {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { rawValue }
    }
}

extension RawRepresentable where RawValue: JSONRepresentable {
    @_documentation(visibility: internal)
    @inlinable public var json: JSON {
        get { rawValue.json }
    }
}
