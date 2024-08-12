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
        case authorizationEndpoint                      = "authorization_endpoint"
        case tokenEndpoint                              = "token_endpoint"
        case userinfoEndpoint                           = "userinfo_endpoint"
        case jwksUri                                    = "jwks_uri"
        case registrationEndpoint                       = "registration_endpoint"
        case scopesSupported                            = "scopes_supported"
        case responseTypesSupported                     = "response_types_supported"
        case responseModesSupported                     = "response_modes_supported"
        case grantTypesSupported                        = "grant_types_supported"
        case acrValuesSupported                         = "acr_values_supported"
        case subjectTypesSupported                      = "subject_types_supported"
        case idTokenSigningAlgValuesSupported           = "id_token_signing_alg_values_supported"
        case idTokenEncryptionAlgValuesSupported        = "id_token_encryption_alg_values_supported"
        case idTokenEncryptionEncValuesSupported        = "id_token_encryption_enc_values_supported"
        case userinfoSigningAlgValuesSupported          = "userinfo_signing_alg_values_supported"
        case userinfoEncryptionAlgValuesSupported       = "userinfo_encryption_alg_values_supported"
        case userinfoEncryptionEncValuesSupported       = "userinfo_encryption_enc_values_supported"
        case requestObjectSigningAlgValuesSupported     = "request_object_signing_alg_values_supported"
        case requestObjectEncryptionAlgValuesSupported  = "request_object_encryption_alg_values_supported"
        case requestObjectEncryptionEncValuesSupported  = "request_object_encryption_enc_values_supported"
        case tokenEndpointAuthMethodsSupported          = "token_endpoint_auth_methods_supported"
        case tokenEndpointAuthSigningAlgValuesSupported = "token_endpoint_auth_signing_alg_values_supported"
        case displayValuesSupported                     = "display_values_supported"
        case claimTypesSupported                        = "claim_types_supported"
        case claimsSupported                            = "claims_supported"
        case serviceDocumentation                       = "service_documentation"
        case claimsLocalesSupported                     = "claims_locales_supported"
        case uiLocalesSupported                         = "ui_locales_supported"
        case claimsParameterSupported                   = "claims_parameter_supported"
        case requestParameterSupported                  = "request_parameter_supported"
        case requestUriParameterSupported               = "request_uri_parameter_supported"
        case requireRequestUriRegistration              = "require_request_uri_registration"
        case opPolicyUri                                = "op_policy_uri"
        case opTosUri                                   = "op_tos_uri"

        // Okta-defined additions
        // https://developer.okta.com/docs/reference/api/oidc/#response-properties-11
        case endSessionEndpoint                                        = "end_session_endpoint"
        case introspectionEndpoint                                     = "introspection_endpoint"
        case deviceAuthorizationEndpoint                               = "device_authorization_endpoint"
        case codeChallengeMethodsSupported                             = "code_challenge_methods_supported"
        case introspectionEndpointAuthMethodsSupported                 = "introspection_endpoint_auth_methods_supported"
        case revocationEndpoint                                        = "revocation_endpoint"
        case revocationEndpointAuthMethodsSupported                    = "revocation_endpoint_auth_methods_supported"
        case backchannelTokenDeliveryModesSupported                    = "backchannel_token_delivery_modes_supported"
        case backchannelAuthenticationRequestSigningAlgValuesSupported = "backchannel_authentication_request_signing_alg_values_supported"
        case dpopSigningAlgValuesSupported                             = "dpop_signing_alg_values_supported"
   }
}
