//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import Testing

@testable import AuthFoundation

enum TestLocalizedError: Error, LocalizedError {
    case nestedError
    
    var errorDescription: String? {
        switch self {
        case .nestedError:
            return "Nested Error"
        }
    }
}

enum TestUnlocalizedError: Error {
    case nestedError
}

@Suite("Error localization tests")
struct ErrorTests {
    @Test("APIClientError")
    func testAPIClientError() {
        #expect(APIClientError.invalidUrl.errorDescription != "invalid_url_description")
        #expect(APIClientError.missingResponse().errorDescription != "missing_response_description")
        #expect(APIClientError.invalidResponse.errorDescription != "invalid_response_description")
        #expect(APIClientError.invalidRequestData.errorDescription != "invalid_request_data_description")
        #expect(APIClientError.missingRefreshSettings.errorDescription != "missing_refresh_settings_description")
        #expect(APIClientError.unknown.errorDescription != "unknown_description")
        
        #expect(APIClientError.cannotParseResponse(error: TestUnlocalizedError.nestedError).errorDescription != "cannot_parse_response_description")
        #expect(APIClientError.cannotParseResponse(error: TestLocalizedError.nestedError).errorDescription?.hasSuffix("Nested Error") ?? false)
        
        #expect(APIClientError.unsupportedContentType(.json).errorDescription != "unsupported_content_type_description")
        
        #expect(APIClientError.httpError(TestUnlocalizedError.nestedError).errorDescription != "http_error_description")
        #expect(APIClientError.httpError(TestLocalizedError.nestedError).errorDescription == "Nested Error")

        #expect(APIClientError.statusCode(404).errorDescription != "status_code_description")
        
        #expect(APIClientError.validation(error: TestUnlocalizedError.nestedError).errorDescription != "http_error_description")
        #expect(APIClientError.validation(error: TestLocalizedError.nestedError).errorDescription == "Nested Error")
    }
    
    @Test("OAuth2Error")
    func testOAuth2Error() {
        #expect(OAuth2Error.invalidUrl.errorDescription != "invalid_url_description")
        #expect(OAuth2Error.cannotComposeUrl.errorDescription != "cannot_compose_url_description")
        #expect(OAuth2Error.missingClientConfiguration.errorDescription != "missing_client_configuration_description")
        #expect(OAuth2Error.signatureInvalid.errorDescription != "signature_invalid_description")
        
        #expect(OAuth2Error.network(error: APIClientError.httpError(TestLocalizedError.nestedError)).errorDescription == "Nested Error")

        #expect(OAuth2Error.server(error: .init(code: "123", description: "AuthError")).errorDescription?.contains("AuthError") ?? false)
        #expect(OAuth2Error.server(error: .init(code: "123", description: nil)).errorDescription != "oauth2_error_code_description")

        #expect(OAuth2Error.missingToken(type: .accessToken).errorDescription != "missing_token_description")
        
        #expect(OAuth2Error.missingLocationHeader.errorDescription != "missing_location_header_description")
        
        #expect(OAuth2Error.error(TestUnlocalizedError.nestedError).errorDescription != "error_description")
        #expect(OAuth2Error.error(TestLocalizedError.nestedError).errorDescription == "Nested Error")
    }
    
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))
    @Test("KeychainError")
    func testKeychainError() {
        #expect(KeychainError.cannotGet(code: noErr).errorDescription != "keychain_cannot_get")
        #expect(KeychainError.cannotList(code: noErr).errorDescription != "keychain_cannot_list")
        #expect(KeychainError.cannotSave(code: noErr).errorDescription != "keychain_cannot_save")
        #expect(KeychainError.cannotUpdate(code: noErr).errorDescription != "keychain_cannot_update")
        #expect(KeychainError.cannotDelete(code: noErr).errorDescription != "keychain_cannot_delete")
        #expect(KeychainError.accessControlInvalid(code: 0, description: "error").errorDescription != "keychain_access_control_invalid")
        #expect(KeychainError.notFound.errorDescription != "keychain_not_found")
        #expect(KeychainError.invalidFormat.errorDescription != "keychain_invalid_format")
        #expect(KeychainError.invalidAccessibilityOption.errorDescription != "keychain_invalid_accessibility_option")
        #expect(KeychainError.missingAccount.errorDescription != "keychain_missing_account")
        #expect(KeychainError.missingValueData.errorDescription != "keychain_missing_value_data")
        #expect(KeychainError.missingAttribute.errorDescription != "keychain_missing_attribute")
    }
    #endif
    
    @Test("JWTError")
    func testJWTError() {
        #expect(JWTError.invalidBase64Encoding.errorDescription != "jwt_invalid_base64_encoding")
        #expect(JWTError.badTokenStructure.errorDescription != "jwt_bad_token_structure")
        #expect(JWTError.invalidIssuer.errorDescription != "jwt_invalid_issuer")
        #expect(JWTError.invalidAudience.errorDescription != "jwt_invalid_audience")
        #expect(JWTError.invalidSubject.errorDescription != "jwt_invalid_subject")
        #expect(JWTError.invalidAuthenticationTime.errorDescription != "jwt_invalid_authentication_time")
        #expect(JWTError.issuerRequiresHTTPS.errorDescription != "jwt_issuer_requires_https")
        #expect(JWTError.invalidSigningAlgorithm.errorDescription != "jwt_invalid_signing_algorithm")
        #expect(JWTError.expired.errorDescription != "jwt_token_expired")
        #expect(JWTError.issuedAtTimeExceedsGraceInterval.errorDescription != "jwt_issuedAt_time_exceeds_grace_interval")
        #expect(JWTError.nonceMismatch.errorDescription != "jwt_nonce_mismatch")
        #expect(JWTError.invalidKey.errorDescription != "jwt_invalid_key")
        #expect(JWTError.signatureInvalid.errorDescription != "jwt_signature_invalid")
        #expect(JWTError.signatureVerificationUnavailable.errorDescription != "jwt_signature_verification_unavailable")
        #expect(JWTError.cannotGenerateHash.errorDescription != "jwt_cannot_generate_hash")

        #expect(JWTError.cannotCreateKey(code: 123, description: "Description").errorDescription != "jwt_cannot_create_key")
        #expect(JWTError.unsupportedAlgorithm(.es384).errorDescription != "jwt_unsupported_algorithm")
    }
    
    @Test("ClaimError")
    func testClaimError() {
        #expect(ClaimError.missingRequiredValue(key: "meow").errorDescription != "claim.missing_required_value")
        #expect(ClaimError.missingRequiredValue(key: "meow").errorDescription?.localizedStandardContains("meow") ?? false)
    }
    
    @Test("CredentialError")
    func testCredentialError() {
        #expect(CredentialError.missingCoordinator.errorDescription != "credential.missing_coordinator")
        #expect(CredentialError.incorrectClientConfiguration.errorDescription != "credential.incorrect_configuration")
        #expect(CredentialError.metadataConsistency.errorDescription != "credential.metadata_consistency")
    }

    @Test("PropertyListConfigurationError")
    func testPropertyListConfigurationError() {
        typealias PlistError = OAuth2Client.PropertyListConfigurationError
        #expect(PlistError.defaultPropertyListNotFound.errorDescription != "plist_configuration.default_not_found")
        #expect(PlistError.invalidPropertyList(url: URL(string: "urn://foo/bar")!).errorDescription != "plist_configuration.invalid_property_list")
        #expect(PlistError.cannotParsePropertyList(nil).errorDescription != "plist_configuration.cannot_parse_message")
        #expect(PlistError.missingConfigurationValues.errorDescription != "plist_configuration.missing_configuration_values")
        #expect(PlistError.invalidConfiguration(name: "foo", value: "value").errorDescription != "plist_configuration.invalid_configuration")

        #expect(PlistError.invalidPropertyList(url: URL(string: "urn://foo/bar")!)
            .errorDescription?
            .localizedStandardContains("bar") ?? false)
        #expect(PlistError.cannotParsePropertyList(TestLocalizedError.nestedError)
            .errorDescription?
            .localizedStandardContains("Nested Error") ?? false)
        #expect(PlistError.invalidConfiguration(name: "foo", value: "bar")
            .errorDescription?
            .localizedStandardContains("foo") ?? false)
        #expect(PlistError.invalidConfiguration(name: "foo", value: "bar")
            .errorDescription?
            .localizedStandardContains("bar") ?? false)
    }
    
    @Test("TokenError")
    func testTokenError() {
        #expect(TokenError.contextMissing.errorDescription != "token_error.context_missing")
        #expect(TokenError.tokenNotFound(id: "foo").errorDescription != "token_error.not_found")
        #expect(TokenError.cannotReplaceToken.errorDescription != "token_error.cannot_replace")
        #expect(TokenError.duplicateTokenAdded.errorDescription != "token_error.duplicate_added")
        #expect(TokenError.invalidConfiguration.errorDescription != "token_error.invalid_configuration")

    }

    @Test("OktaAPIError")
    func testOktaAPIError() throws {
        let json = """
            {
                "errorCode": "Error",
                "errorSummary": "Summary",
                "errorLink": "Link",
                "errorId": "ABC123",
                "errorCauses": ["Cause"]
            }
        """.data(using: .utf8)!
        let error = try defaultJSONDecoder().decode(OktaAPIError.self, from: json)
        #expect(error.code ==  "Error")
        #expect(error.summary ==  "Summary")
        #expect(error.link ==  "Link")
        #expect(error.id ==  "ABC123")
        #expect(error.causes ==  ["Cause"])
    }
    
    @Test("OAuth2ServerError")
    func testOAuth2ServerError() throws {
        let json = """
            {
                "error": "invalid_request",
                "errorDescription": "Description"
            }
        """.data(using: .utf8)!
        let error = try defaultJSONDecoder().decode(OAuth2ServerError.self, from: json)
        #expect(error.code ==  .invalidRequest)
        #expect(error.description ==  "Description")
        #expect(error.errorDescription ==  "Authentication error: Description (invalid_request).")
    }
    
    @Test("OAuth2ServerErrorCodes")
    func testOAuth2ServerErrorCodes() {
        typealias Code = OAuth2ServerError.Code
        #expect(Code(rawValue: "access_denied") ==  .accessDenied)
        #expect(Code.accessDenied.rawValue ==  "access_denied")
        #expect(Code.accessDenied ==  Code.other(code: "access_denied"))
    }
}
