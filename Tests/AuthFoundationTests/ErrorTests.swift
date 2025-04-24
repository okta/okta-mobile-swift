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

import XCTest
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

final class ErrorTests: XCTestCase {
    func testAPIClientError() {
        XCTAssertNotEqual(APIClientError.invalidUrl.errorDescription,
                          "invalid_url_description")
        XCTAssertNotEqual(APIClientError.missingResponse.errorDescription,
                          "missing_response_description")
        XCTAssertNotEqual(APIClientError.invalidResponse.errorDescription,
                          "invalid_response_description")
        XCTAssertNotEqual(APIClientError.invalidRequestData.errorDescription,
                          "invalid_request_data_description")
        XCTAssertNotEqual(APIClientError.missingRefreshSettings.errorDescription,
                          "missing_refresh_settings_description")
        XCTAssertNotEqual(APIClientError.unknown.errorDescription,
                          "unknown_description")
        
        XCTAssertNotEqual(APIClientError.cannotParseResponse(error: TestUnlocalizedError.nestedError).errorDescription,
                          "cannot_parse_response_description")
        XCTAssertTrue(APIClientError.cannotParseResponse(error: TestLocalizedError.nestedError).errorDescription?.hasSuffix("Nested Error") ?? false)
        
        XCTAssertNotEqual(APIClientError.unsupportedContentType(.json).errorDescription,
                          "unsupported_content_type_description")
        
        XCTAssertNotEqual(APIClientError.httpError(TestUnlocalizedError.nestedError).errorDescription,
                          "http_error_description")
        XCTAssertEqual(APIClientError.httpError(TestLocalizedError.nestedError).errorDescription,
                       "Nested Error")

        XCTAssertNotEqual(APIClientError.statusCode(404).errorDescription,
                          "status_code_description")
        
        XCTAssertNotEqual(APIClientError.validation(error: TestUnlocalizedError.nestedError).errorDescription,
                          "http_error_description")
        XCTAssertEqual(APIClientError.validation(error: TestLocalizedError.nestedError).errorDescription,
                       "Nested Error")
    }
    
    func testOAuth2Error() {
        XCTAssertNotEqual(OAuth2Error.invalidUrl.errorDescription,
                          "invalid_url_description")
        XCTAssertNotEqual(OAuth2Error.cannotComposeUrl.errorDescription,
                          "cannot_compose_url_description")
        XCTAssertNotEqual(OAuth2Error.missingClientConfiguration.errorDescription,
                          "missing_client_configuration_description")
        XCTAssertNotEqual(OAuth2Error.signatureInvalid.errorDescription,
                          "signature_invalid_description")
        
        XCTAssertEqual(OAuth2Error.network(error: APIClientError.httpError(TestLocalizedError.nestedError)).errorDescription,
                          "Nested Error")

        XCTAssertTrue(OAuth2Error.server(error: .init(code: "123", description: "AuthError")).errorDescription?.contains("AuthError") ?? false)
        XCTAssertNotEqual(OAuth2Error.server(error: .init(code: "123", description: nil)).errorDescription,
                          "oauth2_error_code_description")

        XCTAssertNotEqual(OAuth2Error.missingToken(type: .accessToken).errorDescription,
                          "missing_token_description")
        
        XCTAssertNotEqual(OAuth2Error.missingLocationHeader.errorDescription,
                          "missing_location_header_description")
        
        XCTAssertNotEqual(OAuth2Error.error(TestUnlocalizedError.nestedError).errorDescription,
                          "error_description")
        XCTAssertEqual(OAuth2Error.error(TestLocalizedError.nestedError).errorDescription,
                       "Nested Error")
    }
    
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))
    func testKeychainError() {
        XCTAssertNotEqual(KeychainError.cannotGet(code: noErr).errorDescription,
                          "keychain_cannot_get")
        XCTAssertNotEqual(KeychainError.cannotList(code: noErr).errorDescription,
                          "keychain_cannot_list")
        XCTAssertNotEqual(KeychainError.cannotSave(code: noErr).errorDescription,
                          "keychain_cannot_save")
        XCTAssertNotEqual(KeychainError.cannotUpdate(code: noErr).errorDescription,
                          "keychain_cannot_update")
        XCTAssertNotEqual(KeychainError.cannotDelete(code: noErr).errorDescription,
                          "keychain_cannot_delete")
        XCTAssertNotEqual(KeychainError.accessControlInvalid(code: 0, description: "error").errorDescription,
                          "keychain_access_control_invalid")
        XCTAssertNotEqual(KeychainError.notFound.errorDescription,
                          "keychain_not_found")
        XCTAssertNotEqual(KeychainError.invalidFormat.errorDescription,
                          "keychain_invalid_format")
        XCTAssertNotEqual(KeychainError.invalidAccessibilityOption.errorDescription,
                          "keychain_invalid_accessibility_option")
        XCTAssertNotEqual(KeychainError.missingAccount.errorDescription,
                          "keychain_missing_account")
        XCTAssertNotEqual(KeychainError.missingValueData.errorDescription,
                          "keychain_missing_value_data")
        XCTAssertNotEqual(KeychainError.missingAttribute.errorDescription,
                          "keychain_missing_attribute")
    }
    #endif
    
    func testJWTError() {
        XCTAssertNotEqual(JWTError.invalidBase64Encoding.errorDescription,
                          "jwt_invalid_base64_encoding")
        XCTAssertNotEqual(JWTError.badTokenStructure.errorDescription,
                          "jwt_bad_token_structure")
        XCTAssertNotEqual(JWTError.invalidIssuer.errorDescription,
                          "jwt_invalid_issuer")
        XCTAssertNotEqual(JWTError.invalidAudience.errorDescription,
                          "jwt_invalid_audience")
        XCTAssertNotEqual(JWTError.invalidSubject.errorDescription,
                          "jwt_invalid_subject")
        XCTAssertNotEqual(JWTError.invalidAuthenticationTime.errorDescription,
                          "jwt_invalid_authentication_time")
        XCTAssertNotEqual(JWTError.issuerRequiresHTTPS.errorDescription,
                          "jwt_issuer_requires_https")
        XCTAssertNotEqual(JWTError.invalidSigningAlgorithm.errorDescription,
                          "jwt_invalid_signing_algorithm")
        XCTAssertNotEqual(JWTError.expired.errorDescription,
                          "jwt_token_expired")
        XCTAssertNotEqual(JWTError.issuedAtTimeExceedsGraceInterval.errorDescription,
                          "jwt_issuedAt_time_exceeds_grace_interval")
        XCTAssertNotEqual(JWTError.nonceMismatch.errorDescription,
                          "jwt_nonce_mismatch")
        XCTAssertNotEqual(JWTError.invalidKey.errorDescription,
                          "jwt_invalid_key")
        XCTAssertNotEqual(JWTError.signatureInvalid.errorDescription,
                          "jwt_signature_invalid")
        XCTAssertNotEqual(JWTError.signatureVerificationUnavailable.errorDescription,
                          "jwt_signature_verification_unavailable")
        XCTAssertNotEqual(JWTError.cannotGenerateHash.errorDescription,
                          "jwt_cannot_generate_hash")

        XCTAssertNotEqual(JWTError.cannotCreateKey(code: 123, description: "Description").errorDescription,
                          "jwt_cannot_create_key")
        XCTAssertNotEqual(JWTError.unsupportedAlgorithm(.es384).errorDescription,
                          "jwt_unsupported_algorithm")
    }
    
    func testClaimError() {
        XCTAssertNotEqual(ClaimError.missingRequiredValue(key: "meow").errorDescription,
                          "claim.missing_required_value")
        XCTAssertTrue(ClaimError.missingRequiredValue(key: "meow").errorDescription?.localizedStandardContains("meow") ?? false)
    }
    
    func testCredentialError() {
        XCTAssertNotEqual(CredentialError.missingCoordinator.errorDescription,
                          "credential.missing_coordinator")
        XCTAssertNotEqual(CredentialError.incorrectClientConfiguration.errorDescription,
                          "credential.incorrect_configuration")
        XCTAssertNotEqual(CredentialError.metadataConsistency.errorDescription,
                          "credential.metadata_consistency")
    }

    func testPropertyListConfigurationError() {
        typealias PlistError = OAuth2Client.PropertyListConfigurationError
        XCTAssertNotEqual(PlistError.defaultPropertyListNotFound.errorDescription,
                          "plist_configuration.default_not_found")
        XCTAssertNotEqual(PlistError.invalidPropertyList(url: URL(string: "urn://foo/bar")!).errorDescription,
                          "plist_configuration.invalid_property_list")
        XCTAssertNotEqual(PlistError.cannotParsePropertyList(nil).errorDescription,
                          "plist_configuration.cannot_parse_message")
        XCTAssertNotEqual(PlistError.missingConfigurationValues.errorDescription,
                          "plist_configuration.missing_configuration_values")
        XCTAssertNotEqual(PlistError.invalidConfiguration(name: "foo", value: "value").errorDescription,
                          "plist_configuration.invalid_configuration")

        XCTAssertTrue(PlistError.invalidPropertyList(url: URL(string: "urn://foo/bar")!)
            .errorDescription?
            .localizedStandardContains("bar") ?? false)
        XCTAssertTrue(PlistError.cannotParsePropertyList(TestLocalizedError.nestedError)
            .errorDescription?
            .localizedStandardContains("Nested Error") ?? false)
        XCTAssertTrue(PlistError.invalidConfiguration(name: "foo", value: "bar")
            .errorDescription?
            .localizedStandardContains("foo") ?? false)
        XCTAssertTrue(PlistError.invalidConfiguration(name: "foo", value: "bar")
            .errorDescription?
            .localizedStandardContains("bar") ?? false)
    }
    
    func testTokenError() {
        XCTAssertNotEqual(TokenError.contextMissing.errorDescription,
                          "token_error.context_missing")
        XCTAssertNotEqual(TokenError.tokenNotFound(id: "foo").errorDescription,
                          "token_error.not_found")
        XCTAssertNotEqual(TokenError.cannotReplaceToken.errorDescription,
                          "token_error.cannot_replace")
        XCTAssertNotEqual(TokenError.duplicateTokenAdded.errorDescription,
                          "token_error.duplicate_added")
        XCTAssertNotEqual(TokenError.invalidConfiguration.errorDescription,
                          "token_error.invalid_configuration")

    }

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
        let error = try defaultJSONDecoder.decode(OktaAPIError.self, from: json)
        XCTAssertEqual(error.code, "Error")
        XCTAssertEqual(error.summary, "Summary")
        XCTAssertEqual(error.link, "Link")
        XCTAssertEqual(error.id, "ABC123")
        XCTAssertEqual(error.causes, ["Cause"])
    }
    
    func testOAuth2ServerError() throws {
        let json = """
            {
                "error": "invalid_request",
                "errorDescription": "Description"
            }
        """.data(using: .utf8)!
        let error = try defaultJSONDecoder.decode(OAuth2ServerError.self, from: json)
        XCTAssertEqual(error.code, .invalidRequest)
        XCTAssertEqual(error.description, "Description")
        XCTAssertEqual(error.errorDescription, "Authentication error: Description (invalid_request).")
    }
    
    func testOAuth2ServerErrorCodes() {
        typealias Code = OAuth2ServerError.Code
        XCTAssertEqual(Code(rawValue: "access_denied"), .accessDenied)
        XCTAssertEqual(Code.accessDenied.rawValue, "access_denied")
        XCTAssertEqual(Code.accessDenied, Code.other(code: "access_denied"))
    }
}
