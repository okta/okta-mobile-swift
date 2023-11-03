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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
class TestAuthenticationServicesProvider: AuthenticationServicesProvider {
    override func createSession(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> AuthenticationServicesProviderSession {
        MockAuthenticationServicesProviderSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }
}

@available(iOS 13.0, *)
class AuthenticationServicesProviderTests: ProviderTestBase {
    var provider: AuthenticationServicesProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        provider = TestAuthenticationServicesProvider(loginFlow: loginFlow, logoutFlow: logoutFlow, from: nil, delegate: delegate)
    }
    
    override func tearDownWithError() throws {
        provider.authenticationSession?.cancel()
        MockAuthenticationServicesProviderSession.redirectUri = nil
        MockAuthenticationServicesProviderSession.redirectError = nil
    }
    
    func testSuccessfulAuthentication() throws {
        provider.start(context: .init(state: "state"), additionalParameters: nil)
        try waitFor(.authenticateUrl)
        
        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)
        
        let redirectUrl = URL(string: "com.example:/callback?code=abc123&state=state")
        provider.process(url: redirectUrl, error: nil)
        try waitFor(.token)
        
        XCTAssertNotNil(delegate.token)
        XCTAssertNil(delegate.error)
        XCTAssertNil(provider.authenticationSession)
    }

    func testErrorResponse() throws {
        provider.start(context: .init(state: "state"), additionalParameters: nil)
        try waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        let redirectUrl = URL(string: "com.example:/callback?state=state&error=errorname&error_description=This+Thing+Failed")
        let error = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        provider.process(url: redirectUrl, error: error)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
        XCTAssertNil(provider.authenticationSession)
        
        let webAuthError = try XCTUnwrap(delegate.error as? WebAuthenticationError)
        if case let .serverError(serverError) = webAuthError {
            XCTAssertEqual(serverError.code, .other(code: "errorname"))
            XCTAssertEqual(serverError.description, "This Thing Failed")
        } else {
            XCTFail("Did not get the appropriate error response type")
        }
    }

    func testUserCancelled() throws {
        provider.start(context: .init(state: "state"), additionalParameters: nil)
        try waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        let error = NSError(domain: ASWebAuthenticationSessionErrorDomain,
                            code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                            userInfo: nil)
        provider.process(url: nil, error: error)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
        XCTAssertNil(provider.authenticationSession)
    }

    func testNoResponse() throws {
        provider.start(context: .init(state: "state"), additionalParameters: nil)
        try waitFor(.authenticateUrl)

        XCTAssertNotNil(provider.authenticationSession)
        let session = try XCTUnwrap(provider.authenticationSession as? MockAuthenticationServicesProviderSession)
        XCTAssertTrue(session.startCalled)

        provider.process(url: nil, error: nil)
        XCTAssertNil(delegate.token)
        XCTAssertNotNil(delegate.error)
        XCTAssertNil(provider.authenticationSession)
    }
    
    func testLogout() throws {
        MockAuthenticationServicesProviderSession.redirectUri = URL(string: "com.example:/logout?foo=bar")
    
        provider.logout(context: .init(idToken: "idToken", state: "state"), additionalParameters: nil)
        try waitFor(.logoutUrl)

        XCTAssertNotNil(provider.authenticationSession)
        provider.processLogout(url: logoutRedirectUri, error: nil)
        
        XCTAssertTrue(delegate.logoutFinished)
        XCTAssertNil(delegate.logoutError)
        XCTAssertNil(provider.authenticationSession)
    }
    
    func testLogoutError() throws {
        MockAuthenticationServicesProviderSession.redirectError = WebAuthenticationError.userCancelledLogin

        provider.logout(context: .init(idToken: "idToken", state: "state"), additionalParameters: nil)
        try waitFor(.logoutUrl)
        
        XCTAssertNotNil(provider.authenticationSession)
        provider.processLogout(url: logoutRedirectUri, error: WebAuthenticationError.missingIdToken)
        
        XCTAssertFalse(delegate.logoutFinished)
        XCTAssertNotNil(delegate.logoutError)
        XCTAssertNil(provider.authenticationSession)
    }
}

#endif
