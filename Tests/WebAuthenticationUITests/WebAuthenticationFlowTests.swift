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

#if canImport(UIKit) || canImport(AppKit)

import XCTest
import AuthenticationServices
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationFlowTests: XCTestCase {
    private let issuer = URL(string: "https://example.okta.com")!
    private let redirectUri = URL(string: "com.example:/callback")!
    private let logoutRedirectUri = URL(string: "com.example:/logout")!
    private let urlSession = URLSessionMock()
    private var client: OAuth2Client!
    
    override func setUpWithError() throws {
        WebAuthentication.providerFactory = WebAuthenticationProviderFactoryMock.self
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              logoutRedirectUri: logoutRedirectUri,
                              session: urlSession)
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
    }
    
    override func tearDownWithError() throws {
        WebAuthentication.resetToDefault()
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testStart() async throws {
        let webAuth = try WebAuthentication(client: client,
                                            additionalParameters: ["testName": name])

        try WebAuthenticationProviderFactoryMock.register(
            result: .success(URL(string: "com.example:/callback?state=qwe&code=the_auth_code")!),
            for: webAuth)

        let token = try await webAuth.signIn(from: nil, context: .init(state: "qwe"))
        XCTAssertEqual(token.refreshToken, "therefreshtoken")

        let provider = try XCTUnwrap(WebAuthenticationProviderFactoryMock.provider(for: webAuth))
        guard case let .opened(authorizeUrl: authorizeUrl, redirectUri: redirectUri) = provider.state
        else {
            XCTFail()
            return
        }
        
        let authorizeQueryItems = authorizeUrl.query?.urlFormDecoded()
        XCTAssertEqual(authorizeQueryItems?["client_id"], "clientId")
        XCTAssertEqual(authorizeQueryItems?["redirect_uri"], "com.example:/callback")
        XCTAssertEqual(authorizeQueryItems?["response_type"], "code")
        XCTAssertEqual(authorizeQueryItems?["state"], "qwe")
        XCTAssertEqual(redirectUri.absoluteString, "com.example:/callback")
    }
    
    func testLogout() async throws {
        let webAuth = try WebAuthentication(client: client,
                                            additionalParameters: ["testName": name])

        try WebAuthenticationProviderFactoryMock.register(
            result: .success(URL(string: "com.example:/logout?state=qwe")!),
            for: webAuth)

        let result = try await webAuth.signOut(from: nil, context: .init(idToken: "idToken", state: "qwe"))
        XCTAssertEqual(result.absoluteString, "com.example:/logout?state=qwe")

        let provider = try XCTUnwrap(WebAuthenticationProviderFactoryMock.provider(for: webAuth))
        guard case let .opened(authorizeUrl: authorizeUrl, redirectUri: redirectUri) = provider.state
        else {
            XCTFail()
            return
        }
        
        let authorizeQueryItems = authorizeUrl.query?.urlFormDecoded()
        XCTAssertEqual(authorizeQueryItems?["client_id"], "clientId")
        XCTAssertEqual(authorizeQueryItems?["post_logout_redirect_uri"], "com.example:/logout")
        XCTAssertEqual(authorizeQueryItems?["id_token_hint"], "idToken")
        XCTAssertEqual(authorizeQueryItems?["state"], "qwe")
        XCTAssertEqual(redirectUri.absoluteString, "com.example:/logout")
    }
    
    func testCancel() async throws {
        let webAuth = try WebAuthentication(client: client,
                                            additionalParameters: ["testName": name])

        try WebAuthenticationProviderFactoryMock.register(
            result: .failure(NSError(domain: ASWebAuthenticationSessionErrorDomain,
                                     code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                                     userInfo: nil)),
            for: webAuth)

        let error = try await XCTAssertThrowsErrorAsync(await webAuth.signIn(from: nil, context: .init(state: "qwe")))
        XCTAssertEqual(error as? WebAuthenticationError, .userCancelledLogin)

        let provider = try XCTUnwrap(WebAuthenticationProviderFactoryMock.provider(for: webAuth))
        guard case .cancelled = provider.state
        else {
            XCTFail()
            return
        }
    }
}

#endif
