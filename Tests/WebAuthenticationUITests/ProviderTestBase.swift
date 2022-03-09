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

#if canImport(UIKit) || canImport(AppKit)

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationProviderDelegateRecorder: WebAuthenticationProviderDelegate {
    private(set) var token: Token?
    private(set) var error: Error?
    var shouldUseEphemeralSession: Bool = true
    
    func authentication(provider: WebAuthenticationProvider, received token: Token) {
        self.token = token
    }
    
    func authentication(provider: WebAuthenticationProvider, received error: Error) {
        self.error = error
    }
    
    func authenticationShouldUseEphemeralSession(provider: WebAuthenticationProvider) -> Bool {
        shouldUseEphemeralSession
    }
    
    func reset() {
        token = nil
        error = nil
        shouldUseEphemeralSession = true
    }
}

class ProviderTestBase: XCTestCase, AuthorizationCodeFlowDelegate {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!
    let delegate = WebAuthenticationProviderDelegateRecorder()

    var authenticationURL: URL?
    var token: Token?
    var error: Error?
    
    enum WaitType {
        case authenticateUrl
        case token
        case error
    }

    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()

        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
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
        flow.add(delegate: self)
        
        delegate.reset()
    }

    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()

        authenticationURL = nil
        token = nil
        error = nil
    }
    
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) where Flow : AuthorizationCodeFlow {
        authenticationURL = url
    }
    
    func authentication<Flow>(flow: Flow, received token: Token) {
        self.token = token
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }

    func waitFor(_ type: WaitType, timeout: TimeInterval = 5.0, pollInterval: TimeInterval = 0.1) {
        let wait = expectation(description: "Receive authentication URL")
        waitFor(type, timeout: timeout, pollInterval: pollInterval) {
            wait.fulfill()
        }
        waitForExpectations(timeout: timeout + 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    fileprivate func waitFor(_ type: WaitType, timeout: TimeInterval, pollInterval: TimeInterval, completion: @escaping() -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + pollInterval) {
            var object: AnyObject?
            switch type {
            case .authenticateUrl:
                object = self.authenticationURL as AnyObject?
            case .token:
                object = self.token
            case .error:
                object = self.error as AnyObject?
            }

            guard object == nil else {
                completion()
                return
            }

            let timeout = timeout - pollInterval
            guard timeout >= pollInterval else {
                completion()
                return
            }

            self.waitFor(type, timeout: timeout, pollInterval: pollInterval, completion: completion)
        }
    }
}

#endif
