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

extension OpenIdConfiguration {
    /// Defines the metadata claims available within an ``OpenIdConfiguration``.
    public enum ProviderMetadata: String, Codable, IsClaim, CodingKey {
        // Provider claims exposed by the OpenID Provider Metadata specification
        // https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
        case issuer
        case authorizationEndpoint
        case tokenEndpoint
        case userinfoEndpoint
        case jwksUri
        case registrationEndpoint
        case scopesSupported
        case responseTypesSupported
        case responseModesSupported
        case grantTypesSupported
        case acrValuesSupported
        case subjectTypesSupported
        case idTokenSigningAlgValuesSupported
        case idTokenEncryptionAlgValuesSupported
        case idTokenEncryptionEncValuesSupported
        case userinfoSigningAlgValuesSupported
        case userinfoEncryptionAlgValuesSupported
        case userinfoEncryptionEncValuesSupported
        case requestObjectSigningAlgValuesSupported
        case requestObjectEncryptionAlgValuesSupported
        case requestObjectEncryptionEncValuesSupported
        case tokenEndpointAuthMethodsSupported
        case tokenEndpointAuthSigningAlgValuesSupported
        case displayValuesSupported
        case claimTypesSupported
        case claimsSupported
        case serviceDocumentation
        case claimsLocalesSupported
        case uiLocalesSupported
        case claimsParameterSupported
        case requestParameterSupported
        case requestUriParameterSupported
        case requireRequestUriRegistration
        case opPolicyUri
        case opTosUri
        
        // Okta-defined additions
        // https://developer.okta.com/docs/reference/api/oidc/#response-properties-11
        case endSessionEndpoint
        case introspectionEndpoint
        case deviceAuthorizationEndpoint
        case codeChallengeMethodsSupported
        case introspectionEndpointAuthMethodsSupported
        case revocationEndpoint
        case revocationEndpointAuthMethodsSupported
        case backchannelTokenDeliveryModesSupported
        case backchannelAuthenticationRequestSigningAlgValuesSupported
        case dpopSigningAlgValuesSupported
    }
}
