//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaDirectAuth

final class ErrorTests: XCTestCase {
    func testOAuth2ErrorInitializers() throws {
        // OAuth2 error is passed through
        XCTAssertEqual(OAuth2Error(OAuth2Error.cannotComposeUrl),
                       OAuth2Error.cannotComposeUrl)
        
        // APIClientErrors are represented as OAuth2Error.network
        XCTAssertEqual(OAuth2Error(APIClientError.invalidRequestData),
                       OAuth2Error.network(error: .invalidRequestData))
        
        // DirectAuthenticationFlowError.network is exposed as OAuth2Error.network
        XCTAssertEqual(OAuth2Error(DirectAuthenticationFlowError.network(error: .invalidRequestData)),
                       OAuth2Error.network(error: .invalidRequestData))
        
        // DirectAuthenticationFlowError.oauth is returned
        XCTAssertEqual(OAuth2Error(DirectAuthenticationFlowError.oauth2(error: .invalidUrl)),
                       OAuth2Error.invalidUrl)
        
        // Other DirectAuthenticationFlowError types are returned as OAuth2Error.error
        XCTAssertEqual(OAuth2Error(DirectAuthenticationFlowError.pollingTimeoutExceeded),
                       OAuth2Error.error(DirectAuthenticationFlowError.pollingTimeoutExceeded))
    }

    func testDirectAuthenticationFlowErrorInitializers() throws {
        // DirectAuthenticationFlowError error is passed through
        XCTAssertEqual(DirectAuthenticationFlowError(DirectAuthenticationFlowError.pollingTimeoutExceeded),
                       .pollingTimeoutExceeded)
        
        // Ensure an OAuth2Error is assigned to .oauth2(error:)
        XCTAssertEqual(DirectAuthenticationFlowError(OAuth2Error.invalidUrl),
                       .oauth2(error: .invalidUrl))

        // Ensure a network error embedded in OAuth2Error becomes the appropriate error type
        XCTAssertEqual(DirectAuthenticationFlowError(OAuth2Error.network(error: .invalidRequestData)),
                       .network(error: .invalidRequestData))

        // Ensure a generic error embedded in OAuth2Error becomes the appropriate error type
        XCTAssertEqual(DirectAuthenticationFlowError(OAuth2Error.error(KeychainError.invalidFormat)),
                       .other(error: KeychainError.invalidFormat))

        // Ensure a APIClientError becomes the appropriate type
        XCTAssertEqual(DirectAuthenticationFlowError(APIClientError.invalidRequestData),
                       .network(error: .invalidRequestData))

        // Ensure a generic error in APIClientError becomes the appropriate type
        XCTAssertEqual(DirectAuthenticationFlowError(APIClientError.serverError(KeychainError.invalidFormat)),
                       .other(error: KeychainError.invalidFormat))

        // Ensure an OAUth2ServerError becomes a .server(error:)
        let serverError = try defaultJSONDecoder.decode(OAuth2ServerError.self, from: """
            {
                "error": "access_denied",
                "errorDescription": "You do not have access"
            }
            """.data(using: .utf8)!)
        XCTAssertEqual(DirectAuthenticationFlowError(APIClientError.serverError(serverError)),
                       .server(error: serverError))
    }
}
