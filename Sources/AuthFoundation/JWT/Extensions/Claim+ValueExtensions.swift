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

/// Extension which introduces single-value conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Retrieve the value using a payload key, converting to the requested ``ClaimConvertable`` type.
    /// - Parameters:
    ///   - key: String payload key name.
    /// - Returns: Value converted to the requested type.
    func value<T: ClaimConvertable>(for key: String) throws -> T  {
        guard let value = T.convert(from: payload[key])
        else {
            throw ClaimError.missingRequiredValue(key: key)
        }
        return value
    }
    
    /// Retrieve the value using a claim enum, converting to the requested ``ClaimConvertable`` type.
    /// - Parameters:
    ///   - claim: Claim enum value.
    /// - Returns: Value converted to the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) throws -> T {
        try value(for: claim.rawValue)
    }

    /// Retrieve the optional value using a payload key, converting to the requested ``ClaimConvertable`` type.
    /// - Parameters:
    ///   - key: String payload key name.
    /// - Returns: Optional value converted to the requested type.
    func value<T: ClaimConvertable>(for key: String) -> T?  {
        T.convert(from: payload[key])
    }

    /// Retrieve the optional value using a claim enum, converting to the requested ``ClaimConvertable`` type.
    /// - Parameters:
    ///   - claim: Claim enum value.
    /// - Returns: Optional value converted to the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) -> T?  {
        value(for: claim.rawValue)
    }
}

/// Extension which introduces array-value conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Returns the value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter key: String payload key name.
    /// - Returns: Value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for key: String) throws -> [T] {
        guard let array = payload[key] as? [ClaimConvertable]
        else {
            throw ClaimError.missingRequiredValue(key: key)
        }
        
        return array.compactMap { T.convert(from: $0) }
    }
    
    /// Returns the value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter claim: The claim type to retrieve.
    /// - Returns: Value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) throws -> [T] {
        try value(for: claim.rawValue)
    }
    
    /// Returns the optional value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter key: String payload key name.
    /// - Returns: Optional value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for key: String) -> [T]? {
        let array = payload[key] as? [ClaimConvertable]
        return array?.compactMap { T.convert(from: $0) }
    }

    /// Returns the optional value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter claim: The claim type to retrieve.
    /// - Returns: Optional value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) -> [T]? {
        value(for: claim.rawValue)
    }
}

/// Extension which introduces dictionary-value conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Returns the value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter key: String payload key name.
    /// - Returns: Value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for key: String) throws -> [String: T] {
        guard let dictionary = payload[key] as? [String: ClaimConvertable]
        else {
            throw ClaimError.missingRequiredValue(key: key)
        }
        
        return dictionary.compactMapValues { T.convert(from: $0) }
    }
    
    /// Returns the value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter claim: The claim type to retrieve.
    /// - Returns: Value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) throws -> [String: T] {
        try value(for: claim.rawValue)
    }
    
    /// Returns the optional value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter key: String payload key name.
    /// - Returns: Optional value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for key: String) -> [String: T]? {
        let dictionary = payload[key] as? [String: ClaimConvertable]
        return dictionary?.compactMapValues { T.convert(from: $0) }
    }

    /// Returns the optional value for the given key as an array of values converted using a``ClaimConvertable`` type.
    /// - Parameter claim: Payload claim to retrieve.
    /// - Returns: Optional value converted to an array of the requested type.
    func value<T: ClaimConvertable>(for claim: ClaimType) -> [String: T]? {
        value(for: claim.rawValue)
    }
}

/// Extension which introduces single-value subscript conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ claim: ClaimType) -> T? {
        value(for: claim)
    }
    
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ key: String) -> T? {
        value(for: key)
    }
}

/// Extension which introduces array-value subscript conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ claim: ClaimType) -> [T]? {
        value(for: claim)
    }
    
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ key: String) -> [T]? {
        value(for: key)
    }
}

/// Extension which introduces dictionary-value subscript conversion functions for ``ClaimConvertable`` types.
public extension HasClaims {
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ claim: ClaimType) -> [String: T]? {
        value(for: claim)
    }
    
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ key: String) -> [String: T]? {
        value(for: key)
    }
}
