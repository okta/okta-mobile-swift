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
import APIClient
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
    func testOAuth2Error() {
        XCTAssertNotEqual(OAuth2Error.invalidUrl.errorDescription,
                          "invalid_url_description")
        XCTAssertNotEqual(OAuth2Error.cannotComposeUrl.errorDescription,
                          "cannot_compose_url_description")
        XCTAssertNotEqual(OAuth2Error.missingClientConfiguration.errorDescription,
                          "missing_client_configuration_description")
        XCTAssertNotEqual(OAuth2Error.signatureInvalid.errorDescription,
                          "signature_invalid_description")
        
        XCTAssertEqual(OAuth2Error.network(error: APIClientError.serverError(TestLocalizedError.nestedError)).errorDescription,
                          "Nested Error")

        XCTAssertTrue(OAuth2Error.oauth2Error(code: "123", description: "AuthError").errorDescription?.contains("AuthError") ?? false)
        XCTAssertNotEqual(OAuth2Error.oauth2Error(code: "123", description: nil).errorDescription,
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
    
    func testOAuth2ServerError() throws {
        let json = """
            {
                "error": "invalid_request",
                "errorDescription": "Description"
            }
        """.data(using: .utf8)!
        let error = try JSONDecoder.apiClientDecoder.decode(OAuth2ServerError.self, from: json)
        XCTAssertEqual(error.code, .invalidRequest)
        XCTAssertEqual(error.description, "Description")
        XCTAssertEqual(error.errorDescription, "Description")
    }
    
    func testOAuth2ServerErrorCodes() {
        typealias Code = OAuth2ServerError.Code
        XCTAssertEqual(Code(rawValue: "access_denied"), .accessDenied)
        XCTAssertEqual(Code.accessDenied.rawValue, "access_denied")
        XCTAssertEqual(Code.accessDenied, Code.other(code: "access_denied"))
    }
}
