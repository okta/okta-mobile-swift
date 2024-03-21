//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Indicates a type that can be used as an enum value for the ``HasClaims/ClaimType`` associated type.
public protocol IsClaim {
    var rawValue: String { get }
    
    init?(rawValue: String)
}

/// Used by classes that contains OAuth2 claims.
///
/// This provides common conveniences for interacting with user or token information within those claims. For example, iterating through ``allClaims-4c54a`` or using keyed subscripting to access specific claims.
public protocol HasClaims {
    associatedtype ClaimType: IsClaim
    
    /// Returns the collection of claims this object contains.
    ///
    /// > Note: This will only return the list of official claims defined in the ``Claim`` enum. For custom claims, please see the ``customClaims`` property.
    var claims: [ClaimType] { get }
    
    /// Returns the collection of custom claims this object contains.
    ///
    /// Unlike the ``claims`` property, this returns values as strings.
    var customClaims: [String] { get }
    
    /// Raw paylaod of claims, as a dictionary representation.
    var payload: [String: Any] { get }
}

public extension HasClaims {
    /// The list of standard claims contained within this JWT token.
    var claims: [ClaimType] {
        payload.keys.compactMap { ClaimType(rawValue: $0) }
    }
    
    /// The list of custom claims contained within this JWT token.
    var customClaims: [String] {
        payload.keys.filter { ClaimType(rawValue: $0) == nil }
    }

    /// Returns a claim value from this JWT token, with the given key and expected return type.
    /// - Returns: The value for the supplied claim.
    func value<T: ClaimConvertable>(_ type: T.Type, for key: String) -> T? {
        T.claim(key, in: self, from: payload[key])
    }

    /// Returns an array of claims from this JWT token, with the given key and expected array element type.
    /// - Returns: The value for the supplied claim.
    func arrayValue<T: ClaimConvertable>(_ type: T.Type, for key: String) -> [T]? {
        guard let array = payload[key] as? [ClaimConvertable]
        else {
            return nil
        }
        
        return array.compactMap { element in
            T.claim(key, in: self, from: element)
        }
    }

    /// Returns an array of claims from this JWT token, with the given key and expected array element type.
    /// - Returns: The value for the supplied claim.
    func arrayValue<T: ClaimConvertable>(_ type: T.Type, for claim: ClaimType) -> [T]? {
        arrayValue(type, for: claim.rawValue)
    }

    /// Return the given claim's Dictionary of ``ClaimConvertable``values.
    subscript<T: ClaimConvertable>(_ claim: String) -> [String: T?]? {
        guard let dict = payload[claim] as? [String: ClaimConvertable]
        else {
            return nil
        }
        
        return dict.mapValues { value in
            T.claim(claim, in: self, from: value)
        }
    }

    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ claim: ClaimType) -> T? {
        self[claim.rawValue]
    }
    
    /// Return the given claim's value, defined with the given enum value, as the expectred ``ClaimConvertable``value type.
    subscript<T: ClaimConvertable>(_ claim: String) -> T? {
        T.claim(claim, in: self, from: payload[claim])
    }
    
    /// Return the given claim's value as the expectred ``ClaimConvertable``value type.
    subscript<T>(_ claim: String) -> T? {
        payload[claim] as? T
    }
    
    /// All claims, across both standard ``claims`` and ``customClaims``.
    var allClaims: [String] {
        Array([
            claims.map(\.rawValue),
            customClaims
        ].joined())
    }
}
