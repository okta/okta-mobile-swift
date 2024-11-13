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
public struct AnyJSON: Sendable {
    /// The string encoding of the JSON data.
    public var stringValue: String { backing.stringValue }
    
    /// The data encoding of the JSON value.
    public var dataValue: Data { backing.dataValue }
    
    /// The ``JSON`` representation of the JSON data.
    public var jsonValue: JSON { backing.jsonValue }
    
    /// Initializes the JSON data based on a string value.
    /// - Parameter string: JSON string.
    public init(_ string: String) {
        self.init(backing: StringStorage(string))
    }
    
    /// Initializes the JSON data based on a data value.
    /// - Parameter data: JSON data.
    public init(_ data: Data) {
        self.init(backing: DataStorage(data))
    }
    
    /// Initializes the JSON data based on a ``JSON`` value.
    /// - Parameter json: The ``JSON`` value.
    public init(_ json: JSON) {
        self.init(backing: JSONStorage(json))
    }
    
    private let backing: any AnyJSONStorage
    private init(backing: any AnyJSONStorage) {
        self.backing = backing
    }
}

fileprivate protocol AnyJSONStorage: Sendable {
    var stringValue: String { get }
    var dataValue: Data { get }
    var jsonValue: JSON { get }
}

extension AnyJSON {
    fileprivate struct StringStorage: AnyJSONStorage {
        let stringValue: String
        let jsonValue: JSON
        var dataValue: Data {
            stringValue.data(using: .utf8) ?? Data()
        }
        
        init(_ string: String) {
            stringValue = string
            jsonValue = (try? JSON(string)) ?? JSON.null
        }
    }

    fileprivate struct DataStorage: AnyJSONStorage {
        let dataValue: Data
        let jsonValue: JSON
        var stringValue: String {
            String(data: dataValue, encoding: .utf8) ?? ""
        }
        
        init(_ data: Data) {
            dataValue = data
            jsonValue = (try? JSON(data)) ?? JSON.null
        }
    }
    
    fileprivate struct JSONStorage: AnyJSONStorage {
        let jsonValue: JSON
        var dataValue: Data {
            guard let anyValue = jsonValue.anyValue else {
                return Data()
            }
            return (try? JSONSerialization.data(withJSONObject: anyValue)) ?? Data()
        }
        var stringValue: String {
            String(data: dataValue, encoding: .utf8) ?? ""
        }
        
        init(_ json: JSON) {
            jsonValue = json
        }
    }
}

/// Represent mixed JSON values as instances of `Any`. This is used to expose API response values to Swift native types where Swift enums are not supported.
public enum JSON: Sendable, Equatable {
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
    public init(_ value: (any Sendable)?) throws {
        guard let value = value
        else {
            self = .null
            return
        }
        
        try self.init(value: value)
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
        try self.init(value: try JSONSerialization.jsonObject(with: value))
    }
    
    private init(value: Any) throws {
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
    
    /// Returns the value as an instance of `Any`.
    public var anyValue: (any Sendable)? {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return value
        case let .bool(value):
            return value
        case let .object(value):
            return value.reduce(into: [String: (any Sendable)?]()) {
                $0[$1.key] = $1.value.anyValue
            }
        case let .array(value):
            return value.map { $0.anyValue }
        case .null:
            return nil
        }
    }
    
    public subscript(index: Int) -> (any Sendable)? {
        guard case let .array(array) = self else {
            return nil
        }

        return array[index]
    }
    
    public subscript(key: String) -> (any Sendable)? {
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
