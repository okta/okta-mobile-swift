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
        
        XCTAssertNotEqual(APIClientError.serverError(TestUnlocalizedError.nestedError).errorDescription,
                          "server_error_description")
        XCTAssertEqual(APIClientError.serverError(TestLocalizedError.nestedError).errorDescription,
                       "Nested Error")

        XCTAssertNotEqual(APIClientError.statusCode(404).errorDescription,
                          "status_code_description")
        
        XCTAssertNotEqual(APIClientError.validation(error: TestUnlocalizedError.nestedError).errorDescription,
                          "server_error_description")
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
                          "signature_invalid")
        
        XCTAssertEqual(OAuth2Error.network(error: APIClientError.serverError(TestLocalizedError.nestedError)).errorDescription,
                          "Nested Error")

        XCTAssertTrue(OAuth2Error.oauth2Error(code: "123", description: "AuthError").errorDescription?.contains("AuthError") ?? false)
        XCTAssertNotEqual(OAuth2Error.oauth2Error(code: "123", description: nil).errorDescription,
                          "oauth2_error_code_description")

        XCTAssertNotEqual(OAuth2Error.missingToken(type: .accessToken).errorDescription,
                          "missing_token_description")
        
        XCTAssertNotEqual(OAuth2Error.error(TestUnlocalizedError.nestedError).errorDescription,
                          "error_description")
        XCTAssertEqual(OAuth2Error.error(TestLocalizedError.nestedError).errorDescription,
                       "Nested Error")
    }
    
    func testKeychainError() {
        XCTAssertNotEqual(KeychainError.cannotGet(code: noErr).errorDescription,
                          "keychain_cannot_get")
        XCTAssertNotEqual(KeychainError.cannotList(code: noErr).errorDescription,
                          "keychain_cannot_list")
        XCTAssertNotEqual(KeychainError.cannotSave(code: noErr).errorDescription,
                          "keychain_cannot_save")
        XCTAssertNotEqual(KeychainError.cannotDelete(code: noErr).errorDescription,
                          "keychain_cannot_delete")
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
    
    func testJWTError() {
        XCTAssertNotEqual(JWTError.invalidBase64Encoding.errorDescription,
                          "invalid_base64_encoding")
        XCTAssertNotEqual(JWTError.badTokenStructure.errorDescription,
                          "bad_token_structure")
        XCTAssertNotEqual(JWTError.invalidIssuer.errorDescription,
                          "invalid_issuer")
        XCTAssertNotEqual(JWTError.invalidAudience.errorDescription,
                          "invalid_audience")
        XCTAssertNotEqual(JWTError.issuerRequiresHTTPS.errorDescription,
                          "issuer_requires_https")
        XCTAssertNotEqual(JWTError.invalidSigningAlgorithm.errorDescription,
                          "invalid_signing_algorithm")
        XCTAssertNotEqual(JWTError.expired.errorDescription,
                          "token_expired")
        XCTAssertNotEqual(JWTError.issuedAtTimeExceedsGraceInterval.errorDescription,
                          "issuedAt_time_exceeds_grace_interval")
        XCTAssertNotEqual(JWTError.invalidKey.errorDescription,
                          "invalid_key")
        XCTAssertNotEqual(JWTError.signatureInvalid.errorDescription,
                          "signature_invalid")
        XCTAssertNotEqual(JWTError.signatureVerificationUnavailable.errorDescription,
                          "signature_verification_unavailable")

        XCTAssertNotEqual(JWTError.cannotCreateKey(code: 123, description: "Description").errorDescription,
                          "cannot_create_key")
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
                "error": "Error",
                "errorDescription": "Description"
            }
        """.data(using: .utf8)!
        let error = try defaultJSONDecoder.decode(OAuth2ServerError.self, from: json)
        XCTAssertEqual(error.code, "Error")
        XCTAssertEqual(error.description, "Description")
        XCTAssertEqual(error.errorDescription, "Description")
    }
}