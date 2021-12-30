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

final class AuthorizationSSOFlowDelegateRecorder: AuthorizationSSOFlowDelegate {
    typealias Flow = AuthorizationSSOFlow
    
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
    
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) {
        self.url = url
    }
}

final class AuthorizationSSOFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let clientMock = OAuth2ClientMock()
    var configuration: AuthorizationSSOFlow.Configuration!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationSSOFlow!
    
    override func setUpWithError() throws {
        configuration = AuthorizationSSOFlow.Configuration(clientId: "clientId",
                                                           scopes: "profile device_sso",
                                                           deviceSecret: "secret",
                                                           idToken: "id_token",
                                                           audience: "auth://default")
        client = OAuth2Client(baseURL: issuer, session: urlSession)
        
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = AuthorizationSSOFlow(configuration, client: client)
    }
    
    func testWithDelegate() throws {
        let delegate = AuthorizationSSOFlowDelegateRecorder()
        flow.add(delegate: delegate)
        
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Begin
        flow.start()
        XCTAssertNotNil(flow.context)
        XCTAssertNotNil(flow.context?.tokenURL)
        XCTAssertTrue(flow.isAuthenticating)
        
        // The url should be taken from `openid-configuration`
        XCTAssertEqual(flow.context?.tokenURL, URL(string: "https://example.okta.com/oauth2/v1/token"))
        XCTAssertTrue(delegate.started)
        XCTAssertNotNil(delegate.url)
        
        // Exchange code
        let expect = expectation(description: "Wait for timer")
        flow.authorize { result in
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
    }
    
    func testAuthenticationSucceeded() {
        let context = AuthorizationSSOFlow.Context(tokenURL: URL(string: "https://example.okta.com/oauth2/v1/token")!)
        let startExpectation = expectation(description: "Expected `start` succeeded")
        
        XCTAssertFalse(flow.isAuthenticating)
        
        flow.start(with: context) { result in
            switch result {
            case .success(let tokenURL):
                XCTAssertEqual(tokenURL, context.tokenURL)
                startExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertTrue(flow.isAuthenticating)
        
        wait(for: [startExpectation], timeout: 2)
        
        
        let authorizeExpectation = expectation(description: "Expected `authorize` succed")
        
        XCTAssertNotNil(flow.context)
        XCTAssertTrue(flow.isAuthenticating)
        
        flow.authorize { result in
            switch result {
            case .success:
                XCTAssertTrue(self.flow.isAuthenticating)
                authorizeExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        
        wait(for: [authorizeExpectation], timeout: 2)
    }
    
#if swift(>=5.5.1) && !os(Linux)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    func testAsyncAuthenticationSucceeded() async throws {
        let context = AuthorizationSSOFlow.Context(tokenURL: URL(string: "https://example.okta.com/oauth2/v1/token")!)
        
        XCTAssertFalse(flow.isAuthenticating)
        
        let tokenURL = try await flow.start(with: context)
        
        XCTAssertEqual(tokenURL, context.tokenURL)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context)
        
        let _ = try await flow.authorize()
        
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNil(flow.context)
    }
#endif
}
