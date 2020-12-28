//
//  JSONValue.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-16.
//

import Foundation

/// Represent mixed JSON values as instances of AnyObject. This is used to expose API response values to NSObject-based class instances
/// where Swift enums are not supported.
enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String:JSONValue])
    case array([JSONValue])
    case null
    
    func toAnyObject() -> AnyObject? {
        switch self {
        case let .string(value):
            return value as AnyObject
        case let .number(value):
            return NSNumber(floatLiteral: value)
        case let .bool(value):
            return NSNumber(booleanLiteral: value)
        case let .object(value):
            return value.reduce(into: [String:AnyObject]()) {
                $0[$1.key] = $1.value.toAnyObject()
            } as AnyObject
        case let .array(value):
            return value.map {
                $0.toAnyObject()
            } as AnyObject
        case .null:
            return NSNull()
        }
    }
}

extension JSONValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Invalid JSON value \(decoder.codingPath)"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
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
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}

extension JSONValue: Hashable {}
