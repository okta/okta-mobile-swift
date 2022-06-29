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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class SessionTokenFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let clientMock = OAuth2ClientMock()
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: SessionTokenFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = client.sessionTokenFlow(redirectUri: redirectUri,
                                       additionalParameters: ["additional": "param"])
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    func testWithBlocks() throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)

        // Authenticate
        let wait = expectation(description: "resume")
        var token: Token?
        flow.start(with: "theSessionToken") { result in
            switch result {
            case .success(let resultToken):
                token = resultToken
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
}
