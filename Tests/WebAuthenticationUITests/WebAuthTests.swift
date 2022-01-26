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
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationUITests: XCTestCase {
    private let issuer = URL(string: "https://example.com")!
    private let redirectUri = URL(string: "com.example:/callback")!
    private let urlSession = URLSessionMock()
    private var flow: AuthorizationCodeFlow!
    private var configuration: AuthorizationCodeFlow.Configuration!
    private var client: OAuth2Client!
    
    override func setUpWithError() throws {
        configuration = AuthorizationCodeFlow.Configuration(clientId: "clientId",
                                                            clientSecret: nil,
                                                            state: nil,
                                                            scopes: "openid profile",
                                                            responseType: .code,
                                                            redirectUri: redirectUri,
                                                            logoutRedirectUri: nil,
                                                            additionalParameters: ["additional": "param"])
        client = OAuth2Client(baseURL: issuer, session: urlSession)
        
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        flow = AuthorizationCodeFlow(configuration, client: client)
    }
    
    func testStart() throws {
        XCTAssertNotNil(WebAuthentication.shared)
        
        let webAuth = WebAuthenticationMock(flow: flow, context: .init(state: "qwe"))
        
        webAuth.start(from: nil) { result in }
        
        let webAuthProvider = try XCTUnwrap(webAuth.provider as? WebAuthenticationProviderMock)

        XCTAssertNotNil(webAuth.completionBlock)
        XCTAssertTrue(webAuthProvider.state == .started)
    }
    
    func testCancel() throws {
        let webAuth = WebAuthenticationMock(flow: flow, context: .init(state: "qwe"))
        
        XCTAssertNil(webAuth.provider)
        
        webAuth.start(from: nil) { result in }
        webAuth.cancel()
        
        let webAuthProvider = try XCTUnwrap(webAuth.provider as? WebAuthenticationProviderMock)

        XCTAssertTrue(webAuthProvider.state == .cancelled)
    }
}
