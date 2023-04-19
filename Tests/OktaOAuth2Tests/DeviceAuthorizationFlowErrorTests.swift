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
@testable import OktaOAuth2

final class DeviceAuthorizationFlowErrorTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: DeviceAuthorizationFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        flow = client.deviceAuthorizationFlow()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testSlowDown() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/device/authorize",
                          data: try data(from: .module, for: "device-authorize", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token-slow_down", in: "MockResponses"),
                          statusCode: 400,
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        DeviceAuthorizationFlow.slowDownInterval = 1

        try performAuthenticationFlow()
    }

    func testAuthorizationPending() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/device/authorize",
                          data: try data(from: .module, for: "device-authorize", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token-authorization_pending", in: "MockResponses"),
                          statusCode: 400,
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        DeviceAuthorizationFlow.slowDownInterval = 1

        try performAuthenticationFlow()
    }

    func performAuthenticationFlow() throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        var wait = expectation(description: "resume")
        var context: DeviceAuthorizationFlow.Context?
        flow.start { result in
            switch result {
            case .success(let response):
                context = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        
        context = try XCTUnwrap(context)
        XCTAssertEqual(flow.context?.deviceCode, context?.deviceCode)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.verificationUri)
        XCTAssertEqual(context, flow.context)
        XCTAssertEqual(flow.context?.verificationUri.absoluteString, "https://example.okta.com/activate")
        XCTAssertEqual(flow.context?.interval, 1)

        // Exchange code
        var token: Token?
        wait = expectation(description: "resume")
        flow.resume(with: context!) { result in
            switch result {
            case .success(let resultToken):
                token = resultToken
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }

}
