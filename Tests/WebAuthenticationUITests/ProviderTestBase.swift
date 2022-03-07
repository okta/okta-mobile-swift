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

class ProviderTestBase: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!
    let delegate = WebAuthenticationProviderDelegateRecorder()

    override func setUpWithError() throws {
        JWT.validator = MockJWTValidator()

        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        urlSession.asyncTasks = false
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/default/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        flow = client.authorizationCodeFlow(redirectUri: redirectUri,
                                            additionalParameters: ["additional": "param"])
        delegate.reset()
    }

    override func tearDownWithError() throws {
        JWT.resetToDefault()
    }
}

#endif
