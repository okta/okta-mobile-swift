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
import AuthenticationServices
@testable import AuthFoundation
@testable import TestCommon
@testable import OAuth2Auth
@testable import BrowserSignin

class BrowserSigninFlowTests: XCTestCase {
    private let issuer = URL(string: "https://example.okta.com")!
    private let redirectUri = URL(string: "com.example:/callback")!
    private let logoutRedirectUri = URL(string: "com.example:/logout")!
    private let urlSession = URLSessionMock()
    private var client: OAuth2Client!

    override func setUp() async throws {
        await MainActor.run {
            BrowserSignin.providerFactory = BrowserSigninProviderFactoryMock.self
        }
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
    
    override func tearDown() async throws {
        await MainActor.run {
            BrowserSignin.resetToDefault()
        }
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    @MainActor
    func testStart() async throws {
        let loginFlow = try AuthorizationCodeFlow(client: client,
                                                  additionalParameters: ["testName": name])
        let webAuth = BrowserSignin(loginFlow: loginFlow, logoutFlow: nil)

        try await BrowserSigninProviderFactoryMock.register(
            result: .success(URL(string: "com.example:/callback?state=qwe&code=the_auth_code")!),
            for: webAuth)

        let token = try await webAuth.signIn(from: nil, context: .init(state: "qwe"))
        XCTAssertEqual(token.refreshToken, "therefreshtoken")

        let optionalProvider = await BrowserSigninProviderFactoryMock.provider(for: webAuth)
        let provider = try XCTUnwrap(optionalProvider)
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

    @MainActor
    func testLogout() async throws {
        let loginFlow = try AuthorizationCodeFlow(client: client,
                                                  additionalParameters: ["testName": name])
        let logoutFlow = SessionLogoutFlow(client: loginFlow.client,
                                           additionalParameters: loginFlow.additionalParameters)
        let webAuth = BrowserSignin(loginFlow: loginFlow, logoutFlow: logoutFlow)

        try await BrowserSigninProviderFactoryMock.register(
            result: .success(URL(string: "com.example:/logout?state=qwe")!),
            for: webAuth)

        let result = try await webAuth.signOut(from: nil, context: .init(idToken: "idToken", state: "qwe"))
        XCTAssertEqual(result.absoluteString, "com.example:/logout?state=qwe")

        let optionalProvider = await BrowserSigninProviderFactoryMock.provider(for: webAuth)
        let provider = try XCTUnwrap(optionalProvider)
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
    
    @available(iOS 12.0, macCatalyst 13.0, macOS 10.15, tvOS 16.0, visionOS 1.0, watchOS 6.2, *)
    func testCancel() async throws {
        let loginFlow = try AuthorizationCodeFlow(client: client,
                                                  additionalParameters: ["testName": name])
        let webAuth = await BrowserSignin(loginFlow: loginFlow, logoutFlow: nil)

        try await BrowserSigninProviderFactoryMock.register(
            result: .failure(NSError(domain: ASWebAuthenticationSessionErrorDomain,
                                     code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                                     userInfo: nil)),
            for: webAuth)

        let error = try await XCTAssertThrowsErrorAsync(await webAuth.signIn(from: nil, context: .init(state: "qwe")))
        XCTAssertEqual(error as? BrowserSigninError, .userCancelledLogin())

        let optionalProvider = await BrowserSigninProviderFactoryMock.provider(for: webAuth)
        let provider = try XCTUnwrap(optionalProvider)
        guard case .cancelled = provider.state
        else {
            XCTFail()
            return
        }
    }
}
