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
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationUITests: XCTestCase {
    private let issuer = URL(string: "https://example.com")!
    private let redirectUri = URL(string: "com.example:/callback")!
    private let logoutRedirectUri = URL(string: "com.example:/logout")!
    private let urlSession = URLSessionMock()
    private var loginFlow: AuthorizationCodeFlow!
    private var logoutFlow: SessionLogoutFlow!
    private var client: OAuth2Client!
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        loginFlow = client.authorizationCodeFlow(redirectUri: redirectUri,
                                            additionalParameters: ["additional": "param"])
        logoutFlow = SessionLogoutFlow(logoutRedirectUri: logoutRedirectUri, client: client)
    }
    
    func testStart() throws {
        let webAuth = WebAuthenticationMock(loginFlow: loginFlow, logoutFlow: logoutFlow)
        
        webAuth.signIn(from: nil, options: [.state("qwe")]) { result in }
        
        let webAuthProvider = try XCTUnwrap(webAuth.provider as? WebAuthenticationProviderMock)

        XCTAssertNotNil(webAuth.completionBlock)
        XCTAssertTrue(webAuthProvider.state == .started)
    }
    
    func testLogout() throws {
        let webAuth = WebAuthenticationMock(loginFlow: loginFlow, logoutFlow: logoutFlow)
        
        webAuth.signOut(from: nil, token: "idToken", options: [.state("qwe")]) { result in }
        
        let provider = try XCTUnwrap(webAuth.provider as? WebAuthenticationProviderMock)
        XCTAssertNil(webAuth.completionBlock)
        XCTAssertNotNil(webAuth.logoutCompletionBlock)
        XCTAssertNotNil(provider.state == .started)
    }
    
    func testCancel() throws {
        let webAuth = WebAuthenticationMock(loginFlow: loginFlow, logoutFlow: logoutFlow)
        
        XCTAssertNil(webAuth.provider)
        
        webAuth.signIn(from: nil, options: [.state("qwe")]) { result in }

        let webAuthProvider = try XCTUnwrap(webAuth.provider as? WebAuthenticationProviderMock)

        webAuth.cancel()
        
        XCTAssertTrue(webAuthProvider.state == .cancelled)
    }
}

#endif
