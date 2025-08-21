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

#if !COCOAPODS
import CommonSupport
#endif

@testable import AuthFoundation
@testable import TestCommon
@testable import OAuth2Auth
@testable import BrowserSignin
import AuthenticationServices

#if !COCOAPODS
import CommonSupport
#endif

class MockAuthenticationServicesProviderSession: NSObject, @unchecked Sendable, AuthenticationServicesProviderSession {
    let url: URL
    let callbackURLScheme: String?
    let callback: (any Equatable)?
    let completionHandler: ASWebAuthenticationSession.CompletionHandler
    var state: State = .initialized
    
    static let result: LockedValue<Result<URL, any Error>?> = nil
    static let startResult: LockedValue<Bool> = true

    enum State {
        case initialized, started, cancelled
    }
    
    required init(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        self.url = url
        self.callbackURLScheme = callbackURLScheme
        self.callback = nil
        self.completionHandler = completionHandler
    }
    
    @available(iOS 17.4, macOS 14.4, watchOS 10.4, tvOS 17.4, visionOS 1.1, *)
    required init(url: URL, callback: ASWebAuthenticationSession.Callback, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        self.url = url
        self.callback = callback
        self.callbackURLScheme = nil
        self.completionHandler = completionHandler
    }

    var presentationContextProvider: (any ASWebAuthenticationPresentationContextProviding)?
    var prefersEphemeralWebBrowserSession = false
    
    var canStart: Bool = true

    func start() -> Bool {
        state = .started
        let result = Self.result.wrappedValue

        Task { @MainActor in
            try? await Task.sleep(delay: 0.5)

            switch result {
            case .success(let url):
                self.completionHandler(url, nil)
            case .failure(let error):
                self.completionHandler(nil, error)
            case nil:
                self.completionHandler(nil, nil)
            }
        }

        return Self.startResult.wrappedValue
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
        
        MockAuthenticationServicesProviderSession.result.wrappedValue = .success(responseUrl)
        let response = try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri)
        
        XCTAssertEqual(response, responseUrl)
        XCTAssertNil(provider.authenticationSession)
    }

    func testErrorResponse() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)
        let responseError = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        
        MockAuthenticationServicesProviderSession.result.wrappedValue = .failure(responseError)
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        guard let webAuthError = response as? BrowserSigninError,
              case let BrowserSigninError.generic(error: error) = webAuthError
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

        MockAuthenticationServicesProviderSession.result.wrappedValue = .failure(error)
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        XCTAssertEqual(response as? BrowserSigninError, .userCancelledLogin(nil))
        XCTAssertNil(provider.authenticationSession)
    }

    func testNoResponse() async throws {
        let authorizeUrl = try XCTUnwrap(authorizeUrl)
        let redirectUri = try XCTUnwrap(redirectUri)

        MockAuthenticationServicesProviderSession.result.wrappedValue = nil
        let response = await XCTAssertThrowsErrorAsync(try await provider.open(authorizeUrl: authorizeUrl, redirectUri: redirectUri))
        
        XCTAssertEqual(response as? BrowserSigninError, .noAuthenticatorProviderResonse)
        XCTAssertNil(provider.authenticationSession)
    }
}

#endif
