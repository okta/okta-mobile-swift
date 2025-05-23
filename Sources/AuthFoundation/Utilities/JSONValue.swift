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

public enum JSONError: Error {
    case cannotDecode(value: (any Sendable)?)
    case invalidContentEncoding
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
        value = .json(json)
    }
}

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
extension AnyJSON: @unchecked Sendable {}
#else
extension AnyJSON: Sendable {}
#endif

/// Represent mixed JSON values as instances of `Any`. This is used to expose API response values to Swift native types where Swift enums are not supported.
public enum JSON: Sendable, Equatable {
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

    public init(_ value: Any) throws {
        if let value = value as? String {
            self = .string(value)
        } else if let value = value as? NSNumber {
            self = .number(value)
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? [String: any Sendable] {
            self = .object(try value.mapValues({ try JSON($0) }))
        } else if let value = value as? [any Sendable] {
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
    
    public subscript(index: Int) -> Any? {
        guard case let .array(array) = self else {
            return nil
        }

        return array[index]
    }
    
    public subscript(key: String) -> Any? {
        guard case let .object(dictionary) = self else {
            return nil
        }

        return dictionary[key]
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

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool ? "true" : "false"
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            // swiftlint:disable force_unwrapping
            // swiftlint:disable force_try
            return try! String(data: encoder.encode(self), encoding: .utf8)!
            // swiftlint:enable force_try
            // swiftlint:enable force_unwrapping
        }
    }
}
