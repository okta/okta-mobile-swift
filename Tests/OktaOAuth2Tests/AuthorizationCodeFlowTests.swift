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
@testable import OktaOAuth2

final class AuthorizationCodeFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let clientMock = OAuth2ClientMock()
    
    func testAuthorizationCodeConstructor() throws {
        let configuration = AuthorizationCodeFlow.Configuration(issuer: issuer,
                                                                clientId: "clientId",
                                                                clientSecret: nil,
                                                                state: nil,
                                                                scopes: "openid profile",
                                                                responseType: .code,
                                                                redirectUri: redirectUri,
                                                                logoutRedirectUri: nil,
                                                                additionalParameters: ["additional": "param"])
        let flow = AuthorizationCodeFlow(configuration, client: clientMock)
        XCTAssertNotNil(flow)
    }
}
