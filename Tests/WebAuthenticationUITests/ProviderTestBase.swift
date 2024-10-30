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
@testable import AuthFoundationTestCommon
@testable import APIClientTestCommon
@testable import JWT

final class WebAuthenticationProviderDelegateRecorder: WebAuthenticationProviderDelegate {
    nonisolated(unsafe) private(set) var token: Token?
    nonisolated(unsafe) private(set) var error: (any Error)?
    nonisolated(unsafe) var shouldUseEphemeralSession: Bool = true
    nonisolated(unsafe) private(set) var logoutFinished = false
    nonisolated(unsafe) private(set) var logoutError: (any Error)?
    
    func authentication(provider: any WebAuthenticationProvider, received token: Token) {
        self.token = token
    }
    
    func authentication(provider: any WebAuthenticationProvider, received error: any Error) {
        self.error = error
    }
    
    func authenticationShouldUseEphemeralSession(provider: any WebAuthenticationProvider) -> Bool {
        shouldUseEphemeralSession
    }
    
    func logout(provider: any WebAuthenticationProvider, finished: Bool) {
        self.logoutFinished = finished
    }
    
    func logout(provider: any WebAuthenticationProvider, received error: any Error) {
        self.logoutError = error
    }
    
    func reset() {
        token = nil
        error = nil
        shouldUseEphemeralSession = true
        logoutError = nil
        logoutFinished = false
    }
}

enum ProviderTestError: Error {
    case didNotFind(ProviderTestBase.WaitType)
}

class ProviderTestBase: XCTestCase, AuthorizationCodeFlowDelegate, SessionLogoutFlowDelegate {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let logoutRedirectUri = URL(string: "com.example:/logout")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var loginFlow: AuthorizationCodeFlow!
    var logoutFlow: SessionLogoutFlow!
    let delegate = WebAuthenticationProviderDelegateRecorder()

    var authenticationURL: URL?
    var logoutURL: URL?
    var token: Token?
    var error: (any Error)?
    
    enum WaitType {
        case authenticateUrl
        case logoutUrl
        case token
        case error
    }

    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        logoutFlow = client.sessionLogoutFlow(logoutRedirectUri: logoutRedirectUri)
        logoutFlow.add(delegate: self)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(filename: "openid-configuration"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(filename: "token"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(filename: "keys"),
                          contentType: "application/json")
        loginFlow = client.authorizationCodeFlow(redirectUri: redirectUri,
                                            additionalParameters: ["additional": "param"])
        loginFlow.add(delegate: self)
        
        delegate.reset()
    }

    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()

        authenticationURL = nil
        logoutURL = nil
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

    func logout<Flow>(flow: Flow, shouldLogoutUsing url: URL) where Flow : SessionLogoutFlow {
        self.logoutURL = url
    }
    
    func logout<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }

    func waitFor(_ type: WaitType, timeout: TimeInterval = 5.0, pollInterval: TimeInterval = 0.1) throws {
        var resultError: (any Error)?
        nonisolated(unsafe) var success: Bool?
        let wait = expectation(description: "Receive authentication URL")
        waitFor(type, timeout: timeout, pollInterval: pollInterval) { result in
            success = result
            wait.fulfill()
        }
        waitForExpectations(timeout: timeout + 1.0) { error in
            resultError = error
        }
        
        if let resultError = resultError {
            throw resultError
        } else if success == false {
            throw ProviderTestError.didNotFind(type)
        }
    }
    
    fileprivate func waitFor(_ type: WaitType, timeout: TimeInterval, pollInterval: TimeInterval, completion: @Sendable @escaping(Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + pollInterval) {
            var object: AnyObject?
            switch type {
            case .authenticateUrl:
                object = self.authenticationURL as AnyObject?
            case .logoutUrl:
                object = self.logoutURL as AnyObject?
            case .token:
                object = self.token
            case .error:
                object = self.error as AnyObject?
            }

            guard object == nil else {
                completion(true)
                return
            }

            let timeout = timeout - pollInterval
            guard timeout >= pollInterval else {
                completion(false)
                return
            }

            self.waitFor(type, timeout: timeout, pollInterval: pollInterval, completion: completion)
        }
    }
}

#endif
