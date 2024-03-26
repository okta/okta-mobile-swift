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

import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class OpenIDConfigurationTests: XCTestCase {
    func testLimitedConfiguration() throws {
        let config = try decode(type: OpenIdConfiguration.self, """
        {
           "authorization_endpoint" : "https://example.okta.com/oauth2/v1/authorize",
           "claims_supported" : [
              "iss",
              "ver",
              "sub",
              "aud",
              "iat",
              "exp",
              "jti",
              "auth_time",
              "amr",
              "idp",
              "nonce",
              "name",
              "nickname",
              "preferred_username",
              "given_name",
              "middle_name",
              "family_name",
              "email",
              "email_verified",
              "profile",
              "zoneinfo",
              "locale",
              "address",
              "phone_number",
              "picture",
              "website",
              "gender",
              "birthdate",
              "updated_at",
              "at_hash",
              "c_hash"
           ],
           "code_challenge_methods_supported" : [
              "S256"
           ],
           "end_session_endpoint" : "https://example.okta.com/oauth2/v1/logout",
           "grant_types_supported" : [
              "authorization_code",
              "implicit",
              "refresh_token",
              "password"
           ],
           "id_token_signing_alg_values_supported" : [
              "RS256"
           ],
           "introspection_endpoint" : "https://example.okta.com/oauth2/v1/introspect",
           "introspection_endpoint_auth_methods_supported" : [
              "client_secret_basic",
              "client_secret_post",
              "client_secret_jwt",
              "private_key_jwt",
              "none"
           ],
           "issuer" : "https://example.okta.com",
           "jwks_uri" : "https://example.okta.com/oauth2/v1/keys",
           "registration_endpoint" : "https://example.okta.com/oauth2/v1/clients",
           "request_object_signing_alg_values_supported" : [
              "HS256",
              "HS384",
              "HS512",
              "RS256",
              "RS384",
              "RS512",
              "ES256",
              "ES384",
              "ES512"
           ],
           "request_parameter_supported" : true,
           "response_modes_supported" : [
              "query",
              "fragment",
              "form_post",
              "okta_post_message"
           ],
           "response_types_supported" : [
              "code",
              "id_token",
              "code id_token",
              "code token",
              "id_token token",
              "code id_token token"
           ],
           "revocation_endpoint" : "https://example.okta.com/oauth2/v1/revoke",
           "revocation_endpoint_auth_methods_supported" : [
              "client_secret_basic",
              "client_secret_post",
              "client_secret_jwt",
              "private_key_jwt",
              "none"
           ],
           "scopes_supported" : [
              "openid",
              "email",
              "profile",
              "address",
              "phone",
              "offline_access",
              "groups"
           ],
           "subject_types_supported" : [
              "public"
           ],
           "token_endpoint" : "https://example.okta.com/oauth2/v1/token",
           "token_endpoint_auth_methods_supported" : [
              "client_secret_basic",
              "client_secret_post",
              "client_secret_jwt",
              "private_key_jwt",
              "none"
           ],
           "userinfo_endpoint" : "https://example.okta.com/oauth2/v1/userinfo"
        }
        """)
        
        XCTAssertEqual(config.issuer.absoluteString, "https://example.okta.com")
        XCTAssertEqual(config.authorizationEndpoint.absoluteString, "https://example.okta.com/oauth2/v1/authorize")
        XCTAssertEqual(config.endSessionEndpoint?.absoluteString, "https://example.okta.com/oauth2/v1/logout")
        XCTAssertEqual(config.introspectionEndpoint?.absoluteString, "https://example.okta.com/oauth2/v1/introspect")
        XCTAssertEqual(config.jwksUri.absoluteString, "https://example.okta.com/oauth2/v1/keys")
        XCTAssertEqual(config.registrationEndpoint?.absoluteString, "https://example.okta.com/oauth2/v1/clients")
        XCTAssertEqual(config.revocationEndpoint?.absoluteString, "https://example.okta.com/oauth2/v1/revoke")
        XCTAssertEqual(config.tokenEndpoint.absoluteString, "https://example.okta.com/oauth2/v1/token")
        XCTAssertEqual(config.userinfoEndpoint?.absoluteString, "https://example.okta.com/oauth2/v1/userinfo")
        
        XCTAssertEqual(config.subjectTypesSupported.first, "public")
    }
    
    func testAppleIdConfiguration() throws {
        let config = try decode(type: OpenIdConfiguration.self, """
        {
           "authorization_endpoint" : "https://appleid.apple.com/auth/authorize",
           "claims_supported" : [
              "aud",
              "email",
              "email_verified",
              "exp",
              "iat",
              "is_private_email",
              "iss",
              "nonce",
              "nonce_supported",
              "real_user_status",
              "sub",
              "transfer_sub"
           ],
           "id_token_signing_alg_values_supported" : [
              "RS256"
           ],
           "issuer" : "https://appleid.apple.com",
           "jwks_uri" : "https://appleid.apple.com/auth/keys",
           "response_modes_supported" : [
              "query",
              "fragment",
              "form_post"
           ],
           "response_types_supported" : [
              "code"
           ],
           "revocation_endpoint" : "https://appleid.apple.com/auth/revoke",
           "scopes_supported" : [
              "openid",
              "email",
              "name"
           ],
           "subject_types_supported" : [
              "pairwise"
           ],
           "token_endpoint" : "https://appleid.apple.com/auth/token",
           "token_endpoint_auth_methods_supported" : [
              "client_secret_post"
           ]
        }
        """)

        XCTAssertNil(config.endSessionEndpoint)
        XCTAssertNil(config.introspectionEndpoint)
        XCTAssertNil(config.registrationEndpoint)
        XCTAssertNil(config.userinfoEndpoint)
        
        let claimsSupported = try XCTUnwrap(config.claimsSupported)
        XCTAssertTrue(claimsSupported.contains(.custom("is_private_email")))
        XCTAssertEqual(config.claimsSupported, [
            .audience,
            .email,
            .emailVerified,
            .expirationTime,
            .issuedAt,
            .custom("is_private_email"),
            .issuer,
            .nonce,
            .custom("nonce_supported"),
            .custom("real_user_status"),
            .subject,
            .custom("transfer_sub"),
        ])
        XCTAssertEqual(config.claimsSupported, [
            .audience,
            .email,
            .emailVerified,
            .expirationTime,
            .issuedAt,
            .isPrivateEmail,
            .issuer,
            .nonce,
            .nonceSupported,
            .realUserStatus,
            .subject,
            .transferSubject,
        ])
    }
}
