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

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationProviderDelegateRecorder: WebAuthenticationProviderDelegate {
    private(set) var token: Token?
    private(set) var error: Error?
    var shouldUseEphemeralSession: Bool = false
    
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
        shouldUseEphemeralSession = false
    }
}

class ProviderTestBase: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    var configuration: AuthorizationCodeFlow.Configuration!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!
    let delegate = WebAuthenticationProviderDelegateRecorder()

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
        urlSession.expect("https://example.com/oauth2/default/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        flow = AuthorizationCodeFlow(configuration, client: client)
        delegate.reset()
    }
}
