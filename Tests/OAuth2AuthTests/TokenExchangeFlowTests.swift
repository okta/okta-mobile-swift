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
@testable import OAuth2Auth

final class TokenExchangeFlowDelegateRecorder: AuthenticationDelegate {
    typealias Flow = TokenExchangeFlow
    
    var token: Token?
    var error: OAuth2Error?
    var url: URL?
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

final class TokenExchangeFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.okta.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: TokenExchangeFlow!
    
    private let tokens: [TokenExchangeFlow.TokenType] = [.actor(type: .deviceSecret, value: "secret"), .subject(type: .idToken, value: "id_token")]
    
    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "profile openid device_sso",
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = client.tokenExchangeFlow()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    func testWithDelegate() async throws {
        let delegate = TokenExchangeFlowDelegateRecorder()
        flow.add(delegate: delegate)
        
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Exchange code
        let _ = try await flow.start(with: tokens)
        await MainActor.yield()

        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
        
        XCTAssertEqual(urlSession.requests.count, 3)
        
        let request = try XCTUnwrap(urlSession.request(matching: "/token"))

        XCTAssertEqual(request.url?.absoluteString, "https://example.okta.com/oauth2/v1/token")
        XCTAssertEqual(request.bodyString, "actor_token=secret&actor_token_type=urn:x-oath:params:oauth:token-type:device-secret&audience=api:%2F%2Fdefault&client_id=clientId&grant_type=urn:ietf:params:oauth:grant-type:token-exchange&scope=profile+openid+device_sso&subject_token=id_token&subject_token_type=urn:ietf:params:oauth:token-type:id_token")
    }

    func testAuthenticationSucceeded() async throws {
        XCTAssertFalse(flow.isAuthenticating)

        let expect = expectation(description: "resume")
        flow.start(with: tokens) { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }

            expect.fulfill()
        }
        await fulfillment(of: [expect], timeout: .standard)

        XCTAssertFalse(flow.isAuthenticating)

        XCTAssertEqual(urlSession.requests.count, 3)

        let request = try XCTUnwrap(urlSession.request(matching: "/token"))

        XCTAssertEqual(request.url?.absoluteString, "https://example.okta.com/oauth2/v1/token")
        XCTAssertEqual(request.bodyString, "actor_token=secret&actor_token_type=urn:x-oath:params:oauth:token-type:device-secret&audience=api:%2F%2Fdefault&client_id=clientId&grant_type=urn:ietf:params:oauth:grant-type:token-exchange&scope=profile+openid+device_sso&subject_token=id_token&subject_token_type=urn:ietf:params:oauth:token-type:id_token")
    }

    func testAsyncAuthenticationSucceeded() async throws {
        XCTAssertFalse(flow.isAuthenticating)

        let _ = try await flow.start(with: tokens)
        
        XCTAssertFalse(flow.isAuthenticating)

        XCTAssertEqual(urlSession.requests.count, 3)
        
        let request = try XCTUnwrap(urlSession.request(matching: "/token"))

        XCTAssertEqual(request.url?.absoluteString, "https://example.okta.com/oauth2/v1/token")
        XCTAssertEqual(request.bodyString, "actor_token=secret&actor_token_type=urn:x-oath:params:oauth:token-type:device-secret&audience=api:%2F%2Fdefault&client_id=clientId&grant_type=urn:ietf:params:oauth:grant-type:token-exchange&scope=profile+openid+device_sso&subject_token=id_token&subject_token_type=urn:ietf:params:oauth:token-type:id_token")
    }
}
