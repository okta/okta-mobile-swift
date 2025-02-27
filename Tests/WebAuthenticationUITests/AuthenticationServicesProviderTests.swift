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
    var state: State = .initialized
    
    static var result: Result<URL, Error>?
    static var startResult: Bool = true
    
    enum State {
        case initialized, started, cancelled
    }
    
    required init(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        self.url = url
        self.callbackURLScheme = callbackURLScheme
        self.completionHandler = completionHandler
    }
    
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    var prefersEphemeralWebBrowserSession = false
    
    var canStart: Bool = true
    
    func start() -> Bool {
        state = .started
        let result = Self.result
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            switch result {
            case .success(let url):
                self.completionHandler(url, nil)
            case .failure(let error):
                self.completionHandler(nil, error)
            case nil:
                self.completionHandler(nil, nil)
            }
        }
        return Self.startResult
    }
    
    func cancel() {
        state = .cancelled
    }
}

@available(iOS 13.0, *)
class AuthenticationServicesProviderTests: XCTestCase {
    var provider: AuthenticationServicesProvider!
    let authorizeUrl = URL(string: "https://example.okta.com/oauth2/v1/authorize?client_id=clientId&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123")
    let redirectUri = URL(string: "com.example:/callback")
    let successResponseUrl = URL(string: "com.example:/callback?code=abc123&state=state")

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        AuthenticationServicesProvider.authenticationSessionClass = MockAuthenticationServicesProviderSession.self
        provider = try AuthenticationServicesProvider(from: nil, usesEphemeralSession: true)
    }
    
    override func tearDownWithError() throws {
        AuthenticationServicesProvider.resetToDefault()
    }
    
    func testSuccessfulRedirection() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)
        let responseUrl = try XCTUnwrap(successResponseUrl)
        
        MockAuthenticationServicesProviderSession.result = .success(responseUrl)
        let response = try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri)
        
        XCTAssertEqual(response, responseUrl)
        XCTAssertNil(provider.authenticationSession)
    }

    func testErrorResponse() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)
        let responseError = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        
        MockAuthenticationServicesProviderSession.result = .failure(responseError)
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        guard let webAuthError = response as? WebAuthenticationError,
              case let WebAuthenticationError.generic(error: error) = webAuthError
        else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(error as NSError, responseError)
        XCTAssertNil(provider.authenticationSession)
    }
    
    func testUserCancelled() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)
        let error = NSError(domain: ASWebAuthenticationSessionErrorDomain,
                            code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                            userInfo: nil)

        MockAuthenticationServicesProviderSession.result = .failure(error)
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        XCTAssertEqual(response as? WebAuthenticationError, .userCancelledLogin)
        XCTAssertNil(provider.authenticationSession)
    }

    func testNoResponse() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)

        MockAuthenticationServicesProviderSession.result = nil
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        XCTAssertEqual(response as? WebAuthenticationError, .noAuthenticatorProviderResonse)
        XCTAssertNil(provider.authenticationSession)
    }
}

#endif
