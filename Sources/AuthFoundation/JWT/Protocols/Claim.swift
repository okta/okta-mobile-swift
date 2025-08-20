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
public protocol IsClaim: RawRepresentable<String>, Sendable, Hashable, Equatable {}

/// Used by classes that contains OAuth2 claims.
///
/// This provides common conveniences for interacting with user or token information within those claims. For example, iterating through ``allClaims`` or using keyed subscripting to access specific claims.
///
/// Please see the <doc:WorkingWithClaims> documentation for a bigger in-depth discussion around claims.
public protocol HasClaims {
    associatedtype ClaimType: IsClaim
    
    /// Raw payload of claims, as a dictionary representation.
    ///
    /// Types conforming to this protocol must return the raw payload of claim values. The convenience functions used for loading and converting claims are made available through extensions to this protocol.
    var claimContent: [String: any Sendable] { get }
}

public extension HasClaims {
    /// Returns the collection of claims this object contains.
    ///
    /// > Note: This will only return the list of official claims defined in the ``ClaimType`` enum corresponding to this claim container. For custom claims, please see the ``customClaims`` property.
    var claims: [ClaimType] {
        claimContent.keys.compactMap { ClaimType(rawValue: $0) }
    }
    
    /// Returns the collection of custom claims this object contains.
    ///
    /// Unlike the ``claims`` property, this returns values as strings.
    var customClaims: [String] {
        claimContent.keys.filter { ClaimType(rawValue: $0) == nil }
    }

    /// All claims, across both standard ``claims`` and ``customClaims``.
    var allClaims: [String] {
        Array([
            claims.map(\.rawValue),
            customClaims
        ].joined())
    }
}
