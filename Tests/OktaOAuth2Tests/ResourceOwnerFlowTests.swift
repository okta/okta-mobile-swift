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

class AuthenticationDelegateRecorder: AuthenticationDelegate {
    var token: Token?
    var error: OAuth2Error?
    var started = false
    var finished = false
    
    func authenticationStarted<Flow>(flow: Flow) {
        started = true
    }
    
    func authenticationFinished<Flow>(flow: Flow) {
        finished = true
    }

    func authentication<Flow>(flow: Flow, received token: Token) {
        self.token = token
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }
}

final class ResourceOwnerFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: ResourceOwnerFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
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
        flow = client.resourceOwnerFlow()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    func testWithDelegate() async throws {
        let delegate = AuthenticationDelegateRecorder()
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Authenticate
        let token = try await flow.start(username: "username", password: "password")
        await MainActor.yield()

        XCTAssertTrue(delegate.started)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertEqual(token, delegate.token)
        XCTAssertTrue(delegate.finished)
    }

    func testWithBlocks() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)

        // Authenticate
        let wait = expectation(description: "resume")
        nonisolated(unsafe) var token: Token?
        flow.start(username: "username", password: "password") { result in
            switch result {
            case .success(let resultToken):
                token = resultToken
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        await fulfillment(of: [wait], timeout: 1)

        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }

    func testWithAsync() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)

        // Authenticate
        let token = try await flow.start(username: "username", password: "password")

        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
}
