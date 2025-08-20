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

/// Represents types whose value can be used as the root of a ``JSON`` object.
public protocol JSONRootValue: JSONValueConvertible {}

/// Represents types whose values can be converted to a ``JSON/Value``.
public protocol JSONValueConvertible: Sendable {
    /// The ``JSON/Value`` representation of this type.
    var jsonValue: JSON.Value { get }
}

/// Represents types whose values can be converted to a ``JSON/Primitive``.
public protocol JSONPrimitiveConvertible: Sendable {
    /// The ``JSON/Primitive`` representation of this type.
    var primitive: JSON.Primitive { get }
}

/// Represents ``JSON`` primitive value types that can be represented as Swift Foundation types.
public protocol JSONValueRepresentable: Sendable {
    // The underlying value (String, Int, etc) of this ``JSON`` value.
    var anyValue: (any Sendable)? { get set }
    
    // The `String` representation of the given ``JSON`` value, or `nil` if the value is a different type.
    var string: String? { get set }
    
    // The `Int` representation of the given ``JSON`` value, or `nil` if the value is a different type.
    var int: Int? { get set }
    
    // The `Double` representation of the given ``JSON`` value, or `nil` if the value is a different type.
    var double: Double? { get set }

    // The `Bool` representation of the given ``JSON`` value, or `nil` if the value is a different type.
    var bool: Bool? { get set }
    
    /// Indicates if the JSON value is null.
    var isNull: Bool { get }
}

/// Represents ``JSON`` object value types that can be represented as Swift Foundation types.
public protocol JSONObjectRepresentable: JSONValueRepresentable {
    /// The underlying array of ``JSON/Value`` values, or `nil` if this object is not an array.
    var array: [JSON.Value]? { get set }
    
    /// The underlying object of ``JSON/Value`` values, or `nil` if this is not an object.
    var object: [String: JSON.Value]? { get set }
    
    /// Access the enclosed object using keyed subscripting.
    subscript(_ key: String) -> JSON.Value? { get set }
    
    /// Access the enclosed array using indexed subscripting.
    subscript(_ key: Int) -> JSON.Value? { get set }
}
