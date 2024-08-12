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
    case cannotDecode(value: Any?)
    case invalidContentEncoding
}

@_documentation(visibility: private)
@available(*, deprecated, renamed: "JSON")
public typealias JSONValue = JSON

/// Efficiently represents ``JSON`` values, and exchanges between its String or Data representations.
///
/// JSON data may be imported from multiple sources, be it Data, a String, or an alread-parsed JSON object. Transforming data between these states, and dealing with error conditions every time, can be cumbersome. AnyJSON is a convenience wrapper class that allows underlying JSON to be lazily mapped between types as needed.
public class AnyJSON {
    private enum Value {
        case json(JSON)
        case string(String)
        case data(Data)
    }
    
    private let value: Value
    
    /// The string encoding of the JSON data.
    public lazy var stringValue: String = {
        if case let .string(string) = value {
            return string
        }
        return String(data: dataValue, encoding: .utf8) ?? ""
    }()
    
    /// The data encoding of the JSON value.
    public lazy var dataValue: Data = {
        switch value {
        case .json(let json):
            guard let anyValue = json.anyValue else {
                return Data()
            }
            return (try? JSONSerialization.data(withJSONObject: anyValue)) ?? Data()
        case .string(let string):
            return string.data(using: .utf8) ?? Data()
        case .data(let data):
            return data
        }
    }()
    
    /// The ``JSON`` representation of the JSON data.
    public lazy var jsonValue: JSON = {
        switch value {
        case .json(let json):
            return json
        case .string(let string):
            return (try? JSON(string)) ?? JSON.null
        case .data(let data):
            return (try? JSON(data)) ?? JSON.null
        }
    }()
    
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

/// Represent mixed JSON values as instances of `Any`. This is used to expose API response values to Swift native types where Swift enums are not supported.
public enum JSON: Equatable {
    /// String JSON key value.
    case string(String)

    /// Number JSON key value.
    case number(NSNumber)
    
    /// Boolean JSON key value.
    case bool(Bool)
    
    /// Object JSON key value, containing its own nested key/value pairs.
    case object([String: JSON])
    
    /// Array JSON key value, containing its own nested JSON values.
    case array([JSON])
    
    /// Null JSON key value.
    case null
    
    /// Initializes a JSON object from a variety of supported types.
    /// - Parameter value: Value to represent as a JSON stru ture.
    public init(_ value: Any?) throws {
        guard let value = value
        else {
            self = .null
            return
        }
        
        if let value = value as? String {
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
            throw JSONError.cannotDecode(value: value as Any)
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
        try self.init(JSONSerialization.jsonObject(with: value))
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
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: Encoder) throws {
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
        let type = CFNumberGetType(self as CFNumber)
        switch type {
        case .floatType, .float32Type, .float64Type, .cgFloatType, .doubleType:
            return true
        default:
            return false
        }
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
