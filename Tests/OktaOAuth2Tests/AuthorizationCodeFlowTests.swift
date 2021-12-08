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

final class AuthorizationCodeFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let clientMock = OAuth2ClientMock()
    var configuration: AuthorizationCodeFlow.Configuration!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!

    override func setUpWithError() throws {
        configuration = AuthorizationCodeFlow.Configuration(issuer: issuer,
                                                            clientId: "clientId",
                                                            clientSecret: nil,
                                                            state: nil,
                                                            scopes: "openid profile",
                                                            responseType: .code,
                                                            redirectUri: redirectUri,
                                                            logoutRedirectUri: nil,
                                                            additionalParameters: ["additional": "param"])
        client = OAuth2Client(baseURL: issuer, session: urlSession)
    }
    
    func testConfiguration() throws {
        XCTAssertEqual(configuration.baseURL.absoluteString,
                       "https://example.com/oauth2/v1/")
    }
    
    func testSuccess() throws {
        let delegate = AuthorizationCodeFlowDelegateRecorder()
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        let flow = AuthorizationCodeFlow(configuration, client: client)
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertNil(flow.authenticationURL)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Begin
        let context = AuthorizationCodeFlow.Context(state: "ABC123", pkce: nil)
        try flow.resume(with: context)
        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123#customizedUrl")
        XCTAssertTrue(delegate.started)
        XCTAssertEqual(flow.context?.authenticationURL, delegate.url)
        
        // Exchange code
        try flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!)
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
    }
}
