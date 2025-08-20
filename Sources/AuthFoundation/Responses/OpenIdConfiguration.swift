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
@_exported import JSON

#if !COCOAPODS
import JSON
#endif

/// Describes the configuration of an OpenID server.
///
/// The values exposed from this configuration are typically used during authentication, or when querying a server for its capabilities. This type uses ``HasClaims`` to represent the various provider metadata (represented as ``OpenIdConfiguration/ProviderMetadata``) for returning the full contents of the server's configuration. For more information, please see the ``HasClaims`` documentation.
public struct OpenIdConfiguration: Sendable, Codable, JSONClaimContainer {
    public typealias ClaimType = ProviderMetadata
    
    /// The raw payload of provider metadata claims returned from the OpenID Provider.
    public var payload: [String: any Sendable] { json.claimContent }

    public let json: JSON

    @_documentation(visibility: internal)
    public init(_ json: JSON) throws {
        self.json = json

        let payload = json.claimContent
        issuer = try ProviderMetadata.value(.issuer, in: payload)
        authorizationEndpoint = try ProviderMetadata.value(.authorizationEndpoint, in: payload)
        tokenEndpoint = try ProviderMetadata.value(.tokenEndpoint, in: payload)
        jwksUri = try ProviderMetadata.value(.jwksUri, in: payload)
        responseTypesSupported = try ProviderMetadata.value(.responseTypesSupported, in: payload)
        subjectTypesSupported = try ProviderMetadata.value(.subjectTypesSupported, in: payload)
        idTokenSigningAlgValuesSupported = try ProviderMetadata.value(.idTokenSigningAlgValuesSupported, in: payload)
    }
    
    /// The issuer URL for this OpenID provider.
    public let issuer: URL
    
    /// The URL for this OpenID Provider's authorization endpoint.
    public let authorizationEndpoint: URL
    
    /// The URL for this OpenID Provider's token endpoint.
    public let tokenEndpoint: URL
    
    /// The URL for this OpenID Provider's JWKS endpoint.
    public let jwksUri: URL
    
    /// The list of supported response types for this OpenID Provider.
    public let responseTypesSupported: [String]
    
    /// The list of supported subject types for this OpenID Provider.
    public let subjectTypesSupported: [String]
    
    /// The list of supported ID token signing algorithms for this OpenID Provider.
    public let idTokenSigningAlgValuesSupported: [JWK.Algorithm]

    enum RequiredCodingKeys: String, CodingKey, CaseIterable {
        case issuer
        case authorizationEndpoint
        case tokenEndpoint
        case jwksUri
        case responseTypesSupported
        case subjectTypesSupported
        case idTokenSigningAlgValuesSupported
    }
}

extension OpenIdConfiguration {
    public var endSessionEndpoint: URL? { self[.endSessionEndpoint] }
    public var introspectionEndpoint: URL? { self[.introspectionEndpoint] }
    public var deviceAuthorizationEndpoint: URL? { self[.deviceAuthorizationEndpoint] }
    public var registrationEndpoint: URL? { self[.registrationEndpoint] }
    public var revocationEndpoint: URL? { self[.revocationEndpoint] }
    public var userinfoEndpoint: URL? { self[.userinfoEndpoint] }
    public var scopesSupported: [String]? { self[.scopesSupported] }
    public var responseModesSupported: [String]? { self[.responseModesSupported] }
    public var claimsSupported: [JWTClaim]? { self[.claimsSupported] }
    public var grantTypesSupported: [GrantType]? { self[.grantTypesSupported] }
}
