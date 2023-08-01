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

class AuthorizationCodeFlowDelegateRecorder: AuthorizationCodeFlowDelegate {
    var token: Token?
    var error: OAuth2Error?
    var url: URL?
    var started = false
    var finished = false
    
    func authenticationStarted<Flow: AuthorizationCodeFlow>(flow: Flow) {
        started = true
    }
    
    func authenticationFinished<Flow: AuthorizationCodeFlow>(flow: Flow) {
        finished = true
    }

    func authentication<Flow>(flow: Flow, received token: Token) {
        self.token = token
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }

    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents) {
        urlComponents.fragment = "customizedUrl"
    }
    
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, shouldAuthenticateUsing url: URL) {
        self.url = url
    }
}

final class AuthorizationCodeFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com/oauth2/default")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")

        flow = client.authorizationCodeFlow(redirectUri: redirectUri,
                                            additionalParameters: ["additional": "param"])
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testWithDelegate() throws {
        let delegate = AuthorizationCodeFlowDelegateRecorder()
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Begin
        let context = AuthorizationCodeFlow.Context(state: "ABC123", maxAge: nil, nonce: "nonce_string", pkce: nil)
        var expect = expectation(description: "network request")
        flow.start(with: context, additionalParameters: ["foo": "bar"]) { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123#customizedUrl")
        XCTAssertTrue(delegate.started)
        XCTAssertEqual(flow.context?.authenticationURL, delegate.url)
        
        // Exchange code
        expect = expectation(description: "network request")
        try flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!) { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
    }

    func testWithBlocks() throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        let context = AuthorizationCodeFlow.Context(state: "ABC123", maxAge: nil, nonce: "nonce_string", pkce: nil)
        var wait = expectation(description: "resume")
        var url: URL?
        flow.start(with: context, additionalParameters: ["foo": "bar"]) { result in
            switch result {
            case .success(let redirectUrl):
                url = redirectUrl
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(url, flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123")

        // Exchange code
        var token: Token?
        wait = expectation(description: "resume")
        try flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!) { result in
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

        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }

    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testWithAsync() async throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        let context = AuthorizationCodeFlow.Context(state: "ABC123", maxAge: nil, nonce: "nonce_string", pkce: nil)
        let url = try await flow.start(with: context, additionalParameters: ["foo": "bar"])
        
        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(url, flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123")

        // Exchange code
        let token = try await flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!)
        
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
    #endif
    
    func testAuthorizationCodeFromURL() throws {
        typealias RedirectError = AuthorizationCodeFlow.RedirectError
        
        XCTAssertThrowsError(try flow.authorizationCode(from: URL(string: "https://example.com")!)) { error in
            XCTAssertEqual(error as? AuthenticationError, .flowNotReady)
        }
        
        let wait = expectation(description: "Start the flow")
        flow.start(with: .init(state: "ABC123")) { _ in
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(try flow.authorizationCode(from: URL(string: "com.example:/?state=ABC123&code=foo")!), "foo")
    }
    
    func testTokenRequestParameters() throws {
        let (openIdConfiguration, _) = try openIdConfiguration()
        let pkce = try XCTUnwrap(PKCE())
        
        var request: AuthorizationCodeFlow.TokenRequest
        
        // No authentication
        request = .init(openIdConfiguration: openIdConfiguration,
                        clientConfiguration: try .init(domain: "example.com",
                                                       clientId: "theClientId",
                                                       scopes: "openid profile"),
                        redirectUri: "https://example.com/redirect",
                        grantType: .authorizationCode,
                        grantValue: "abcd123",
                        pkce: pkce,
                        nonce: "nonce_str",
                        maxAge: 60)
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "redirect_uri": "https://example.com/redirect",
                        "grant_type": "authorization_code",
                        "code_verifier": pkce.codeVerifier,
                        "code": "abcd123"
                       ])

        // Client Secret authentication
        request = .init(openIdConfiguration: openIdConfiguration,
                        clientConfiguration: try .init(domain: "example.com",
                                                       clientId: "theClientId",
                                                       scopes: "openid profile",
                                                       authentication: .clientSecret("supersecret")),
                        redirectUri: "https://example.com/redirect",
                        grantType: .authorizationCode,
                        grantValue: "abcd123",
                        pkce: pkce,
                        nonce: "nonce_str",
                        maxAge: 60)
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "client_secret": "supersecret",
                        "redirect_uri": "https://example.com/redirect",
                        "grant_type": "authorization_code",
                        "code_verifier": pkce.codeVerifier,
                        "code": "abcd123"
                       ])
    }
}
