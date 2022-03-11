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

#if canImport(AuthenticationServices)

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI
import AuthenticationServices

class MockAuthenticationServicesProviderSession: AuthenticationServicesProviderSession {
    let url: URL
    let callbackURLScheme: String?
    let completionHandler: ASWebAuthenticationSession.CompletionHandler
    var startCalled = false
    var startResult = true
    var cancelCalled = false
    
    static var redirectUri: URL?
    static var redirectError: Error?
    
    required init(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        self.url = url
        self.callbackURLScheme = callbackURLScheme
        self.completionHandler = completionHandler
    }
    
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    
    var prefersEphemeralWebBrowserSession = false
    
    var canStart: Bool = true
    
    func start() -> Bool {
        startCalled = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            self.completionHandler(
                MockAuthenticationServicesProviderSession.redirectUri,
                MockAuthenticationServicesProviderSession.redirectError)
        }
        return startResult
    }
    
    func cancel() {
        cancelCalled = true
    }
}

class TestAuthenticationServicesProvider: AuthenticationServicesProvider {
    override func createSession(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> AuthenticationServicesProviderSession {
        MockAuthenticationServicesProviderSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }
}

@available(iOS 12.0, *)
class AuthenticationServicesProviderTests: ProviderTestBase {
    var provider: AuthenticationServicesProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        provider = TestAuthenticationServicesProvider(flow: flow, logoutFlow: logoutFlow, from: nil, delegate: delegate)
    }
    
    override func tearDownWithError() throws {
        provider.authenticationSession?.cancel()
    }
    
    func testSuccessfulAuthentication() throws {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)
        
        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)
        
        let redirectUrl = URL(string: "com.example:/callback?code=abc123&state=state")
        provider.process(url: redirectUrl, error: nil)
        waitFor(.token)
        
        XCTAssertNotNil(delegate.token)
        XCTAssertNil(delegate.error)
    }

    func testErrorResponse() throws {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        let redirectUrl = URL(string: "com.example:/callback?state=state&error=errorname&error_description=This+Thing+Failed")
        provider.process(url: redirectUrl, error: nil)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }

    func testUserCancelled() throws {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        let error = NSError(domain: ASWebAuthenticationSessionErrorDomain,
                            code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                            userInfo: nil)
        provider.process(url: nil, error: error)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }

    func testNoResponse() throws {
        provider.start(context: .init(state: "state"))
        waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        provider.process(url: nil, error: nil)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
    }
    
    func testLogout() throws {
        provider.logout(context: .init(idToken: "idToken", state: "state"))
        waitFor(.logoutUrl)

        XCTAssertNotNil(provider.authenticationSession)
        provider.processLogout(url: logoutRedirectUri, error: nil)
        
        XCTAssertTrue(delegate.logoutFinished)
        XCTAssertNil(delegate.logoutError)
    }
    
    func testLogoutError() throws {
        provider.logout(context: .init(idToken: "idToken", state: "state"))
        waitFor(.error)
        
        XCTAssertNotNil(provider.authenticationSession)
        provider.processLogout(url: logoutRedirectUri, error: WebAuthenticationError.missingIdToken)
        
        XCTAssertFalse(delegate.logoutFinished)
        XCTAssertNotNil(delegate.logoutError)
    }
}

#endif
