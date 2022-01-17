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
    let clientMock = OAuth2ClientMock()
    var configuration: TokenExchangeFlow.Configuration!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: TokenExchangeFlow!
    
    private let tokens: [TokenExchangeFlow.TokenType] = [.actor(type: .deviceSecret, value: "secret"), .subject(type: .idToken, value: "id_token")]
    
    override func setUpWithError() throws {
        configuration = TokenExchangeFlow.Configuration(clientId: "clientId",
                                                        scopes: "profile openid device_sso",
                                                        audience: .default)
        client = OAuth2Client(baseURL: issuer, session: urlSession)
        
        urlSession.expect("https://example.okta.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = TokenExchangeFlow(configuration, client: client)
    }
    
    func testWithDelegate() throws {
        let delegate = TokenExchangeFlowDelegateRecorder()
        flow.add(delegate: delegate)
        
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Exchange code
        let expect = expectation(description: "Expected `resume` succeeded")
        flow.resume(with: tokens) { result in
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
    }
    
    func testAuthenticationSucceeded() {
        let authorizeExpectation = expectation(description: "Expected `resume` succeeded")
        
        XCTAssertFalse(flow.isAuthenticating)
        
        flow.resume(with: tokens) { result in
            switch result {
            case .success:
                XCTAssertTrue(self.flow.isAuthenticating)
                
                authorizeExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        XCTAssertFalse(flow.isAuthenticating)
        
        wait(for: [authorizeExpectation], timeout: 2)
    }
    
#if swift(>=5.5.1) && !os(Linux)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    func testAsyncAuthenticationSucceeded() async throws {
        XCTAssertFalse(flow.isAuthenticating)
        
        let _ = try await flow.resume(with: tokens)
        
        XCTAssertFalse(flow.isAuthenticating)
    }
#endif
}
