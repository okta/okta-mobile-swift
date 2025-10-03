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

extension JSON {
    /// Represents a primitive value (aka "leaf node") within a ``JSON`` object.
    public enum Primitive: Codable, Sendable, Equatable, Hashable, JSONValueRepresentable, CustomDebugStringConvertible {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case null

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? container.decode(Int.self) {
                self = .int(value)
            } else if let value = try? container.decode(Double.self) {
                self = .double(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "The container does not hold a decodable primitive value")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let string):
                try container.encode(string)
            case .int(let int):
                try container.encode(int)
            case .double(let double):
                try container.encode(double)
            case .bool(let bool):
                try container.encode(bool)
            case .null:
                try container.encodeNil()
            }
        }

        public var debugDescription: String {
            switch self {
            case .string(let string):
                return string.debugDescription
            case .int(let int):
                return String(int)
            case .double(let double):
                return double.debugDescription
            case .bool(let bool):
                return String(bool)
            case .null:
                return "<null>"
            }
        }
        
        @inlinable public var anyValue: (any Sendable)? {
            get {
                switch self {
                case .string(let value):
                    return value
                case .int(let value):
                    return value
                case .double(let value):
                    return value
                case .bool(let value):
                    return value
                case .null:
                    return nil
                }
            }
            set {
                self = Self._valueFromAny(newValue) ?? .null
            }
        }

        @inlinable public var string: String? {
            get {
                guard case let .string(value) = self else {
                    return nil
                }
                return value
            }
            set {
                if let newValue {
                    self = .string(newValue)
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var int: Int? {
            get {
                guard case let .int(value) = self else {
                    return nil
                }
                return value
            }
            set {
                if let newValue {
                    self = .int(newValue)
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var double: Double? {
            get {
                switch self {
                case .double(let value): return value
                case .int(let value): return Double(value)
                default: return nil
                }
            }
            set {
                if let newValue {
                    if newValue.truncatingRemainder(dividingBy: 1) == 0 {
                        self = .int(Int(newValue))
                    } else {
                        self = .double(newValue)
                    }
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var bool: Bool? {
            get {
                guard case let .bool(value) = self else {
                    return nil
                }

                return value
            }
            set {
                if let newValue {
                    self = .bool(newValue)
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var isNull: Bool {
            if case .null = self { return true }
            return false
        }

        public init(_ value: Any?) throws {
            guard let value = Self._valueFromAny(value) else {
                throw JSONError.invalidJSONValue
            }
            self = value
        }
        
        @inlinable
        static func _valueFromAny(_ value: Any?) -> Self? {
            guard let value else {
                return .null
            }

            switch value {
            case let value as String:
                return .string(value)
            case let value as Int:
                return .int(value)
            case let value as Double:
                return .double(value)
            case let value as Bool:
                return .bool(value)
            case _ as NSNull:
                return .null
            default:
                return nil
            }
        }
    }
    
    /// Represents a value within a ``JSON`` object.
    public enum Value: Codable, Sendable, Equatable, Hashable, JSONValueRepresentable, CustomDebugStringConvertible {
        case primitive(Primitive)
        indirect case array([Value])
        indirect case object([String: Value])

        public static let `null`: Value = .primitive(.null)

        public init(from decoder: any Decoder) throws {
            if let container = try? decoder.container(keyedBy: JSONCodingKeys.self) {
                let result = try container.allKeys.reduce(into: [String: JSON.Value]()) { partialResult, item in
                    partialResult[item.stringValue] = try container.decode(JSON.Value.self, forKey: item)
                }
                self = .object(result)
            }
            
            else if var container = try? decoder.unkeyedContainer() {
                var result: [JSON.Value] = []
                while !container.isAtEnd {
                    result.append(try container.decode(JSON.Value.self))
                }
                self = .array(result)
            }
            
            else if let container = try? decoder.singleValueContainer() {
                self = .primitive(try container.decode(JSON.Primitive.self))
            }

            else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not determine JSON container type"
                ))
            }
        }
        
        public func encode(to encoder: any Encoder) throws {
            switch self {
            case .primitive(let primitive):
                try primitive.encode(to: encoder)
            case .array(let array):
                var container = encoder.unkeyedContainer()
                try array.forEach { item in
                    try container.encode(item)
                }
            case .object(let dictionary):
                var container = encoder.container(keyedBy: JSONCodingKeys.self)
                try dictionary.forEach { key, value in
                    guard let codingKey = JSONCodingKeys(stringValue: key) else {
                        throw EncodingError.invalidValue(key, .init(codingPath: encoder.codingPath,
                                                                    debugDescription: "Could not map the key to a JSONCodingKey"))
                    }
                    
                    try container.encode(value, forKey: codingKey)
                }
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .primitive(let primitive):
                return primitive.debugDescription
            case .array(let array):
                return array.debugDescription
            case .object(let dictionary):
                return dictionary.debugDescription
            }
        }
        
        struct JSONCodingKeys: CodingKey {
            var stringValue: String
            init?(stringValue: String) { self.stringValue = stringValue }
            
            var intValue: Int?
            init?(intValue: Int) {
                self.init(stringValue: "\(intValue)")
                self.intValue = intValue
            }
        }
        
        /// The ``JSON/Primitive`` type for this value, or `nil` if it is not a primitive.
        @inlinable public var primitive: Primitive? {
            if case .primitive(let v) = self { return v }
            return nil
        }

        @inlinable public var string: String? {
            get {
                guard case let .primitive(primitive) = self else {
                    return nil
                }
                return primitive.string
            }
            set {
                if let newValue {
                    self = .primitive(.string(newValue))
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var int: Int? {
            get {
                guard case let .primitive(primitive) = self else {
                    return nil
                }
                return primitive.int
            }
            set {
                if let newValue {
                    self = .primitive(.int(newValue))
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var double: Double? {
            get {
                guard case let .primitive(primitive) = self else {
                    return nil
                }
                return primitive.double
            }
            set {
                if let newValue {
                    if newValue.truncatingRemainder(dividingBy: 1) == 0 {
                        self = .primitive(.int(Int(newValue)))
                    } else {
                        self = .primitive(.double(newValue))
                    }
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var bool: Bool? {
            get {
                guard case let .primitive(primitive) = self else {
                    return nil
                }

                return primitive.bool
            }
            set {
                if let newValue {
                    self = .primitive(.bool(newValue))
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var array: [Value]? {
            get {
                guard case let .array(value) = self else {
                    return nil
                }
                return value
            }
            set {
                if let newValue = newValue {
                    self = .array(newValue)
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var object: [String: Value]? {
            get {
                guard case let .object(value) = self else {
                    return nil
                }
                return value
            }
            set {
                if let newValue {
                    self = .object(newValue)
                } else {
                    self = .null
                }
            }
        }

        @inlinable public var isNull: Bool {
            if case .null = self { return true }
            return false
        }
        
        @inlinable public var anyValue: (any Sendable)? {
            get {
                switch self {
                case .primitive(let value):
                    return value.anyValue
                case .array(let value):
                    return value.map(\.anyValue)
                case .object(let value):
                    return value.mapValues(\.anyValue)
                }
            }
            set {
                switch newValue {
                case let value as Value:
                    self = value
                case let value as Primitive:
                    self = .primitive(value)
                case let value as any JSONValueConvertible:
                    self = value.jsonValue
                default:
                    if let newValue = Primitive._valueFromAny(newValue) {
                        self = .primitive(newValue)
                        return
                    }
                    
                    guard let newValue,
                          JSONSerialization.isValidJSONObject(newValue),
                          let value = try? Value(newValue)
                    else {
                        self = .null
                        return
                    }
                    self = value
                }
            }
        }
        
        public subscript(_ key: String) -> JSON.Value? {
            get {
                object?[key] ?? .null
            }
            set {
                if var newObject = object {
                    newObject[key] = newValue
                    self = .object(newObject)
                }
            }
        }
        
        public subscript(_ key: Int) -> JSON.Value? {
            get {
                array?[key] ?? .null
            }
            set {
                if var newArray = array {
                    newArray[key] = newValue ?? .null
                    self = .array(newArray)
                }
            }
        }

        public init(_ value: Any?) throws {
            guard let value else {
                self = .null
                return
            }

            if let value = value as? Value {
                self = value
                return
            }

            if let value = value as? Primitive {
                self = .primitive(value)
                return
            }
            
            var evaluatedValue = value
            if let data = evaluatedValue as? Data {
                evaluatedValue = try JSONSerialization.jsonObject(with: data, options: [])
            }
            
            if let primitive = Primitive._valueFromAny(evaluatedValue) {
                self = .primitive(primitive)
                return
            }
            
            guard JSONSerialization.isValidJSONObject(evaluatedValue) else {
                if let codable = evaluatedValue as? any Codable {
                    self = try .init(JSONEncoder().encode(codable))
                    return
                }
                throw JSONError.invalidJSONValue
            }

            switch evaluatedValue {
            case let value as Value:
                self = value
            case let value as [any Sendable]:
                self = .array(try value.map { try Value($0) })
            case let value as [String: any Sendable]:
                self = .object(try value.mapValues { try Value($0) })
            default:
                self = .primitive(try Primitive(value))
            }
        }
    }
}

