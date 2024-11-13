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

import XCTest
import APIClient

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
        let error = try JSONDecoder.apiClientDecoder.decode(OktaAPIError.self, from: json)
        XCTAssertEqual(error.code, "Error")
        XCTAssertEqual(error.summary, "Summary")
        XCTAssertEqual(error.link, "Link")
        XCTAssertEqual(error.id, "ABC123")
        XCTAssertEqual(error.causes, ["Cause"])
    }
}
