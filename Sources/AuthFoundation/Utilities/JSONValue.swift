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

public enum JSONValueError: Error {
    case cannotDecode(value: Any)
}

/// Represent mixed JSON values as instances of `Any`. This is used to expose API response values to Swift native types
/// where Swift enums are not supported.
public enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case dictionary([String: JSONValue])
    case array([JSONValue])
    case object(Any)
    case null
    
    public init(_ value: Any?) throws {
        if let value = value as? String {
            self = .string(value)
        } else if let value = value as? NSNumber {
            self = .number(value.doubleValue)
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? [String: Any] {
            self = .dictionary(try value.mapValues({ try JSONValue($0) }))
        } else if let value = value as? [Any] {
            self = .array(try value.map({ try JSONValue($0) }))
        } else if value == nil {
            self = .null
        } else {
            throw JSONValueError.cannotDecode(value: value as Any)
        }
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
        case let .dictionary(value):
            return value.reduce(into: [String: Any?]()) {
                $0[$1.key] = $1.value.anyValue
            }
        case let .array(value):
            return value.map { $0.anyValue }
        case let .object(value):
            return value
        case .null:
            return nil
        }
    }
    
    public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhsValue), .string(let rhsValue)):
            return lhsValue == rhsValue
        case (.number(let lhsValue), .number(let rhsValue)):
            return lhsValue == rhsValue
        case (.bool(let lhsValue), .bool(let rhsValue)):
            return lhsValue == rhsValue
        case (.dictionary(let lhsValue), .dictionary(let rhsValue)):
            return lhsValue == rhsValue
        case (.array(let lhsValue), .array(let rhsValue)):
            return lhsValue == rhsValue
        case (.object(let lhsValue), .object(let rhsValue)):
            if let lhsValue = lhsValue as? AnyHashable,
               let rhsValue = rhsValue as? AnyHashable
            {
                return lhsValue == rhsValue
            } else {
                return false
            }
        case (.null, .null):
            return true
        default:
            return false
        }
    }
}

extension JSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([JSONValue].self) {
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
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .dictionary(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            if let value = value as? Codable {
                try container.encode(value)
            } else {
                throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath,
                                                              debugDescription: "Value is not encodable at \(encoder.codingPath)"))
            }
        case .null:
            try container.encodeNil()
        }
    }
}

extension JSONValue: CustomDebugStringConvertible {
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
        case .object(let obj):
            if let obj = obj as? CustomDebugStringConvertible {
                return obj.debugDescription
            } else {
                return "Custom object \(String(describing: obj))"
            }
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
