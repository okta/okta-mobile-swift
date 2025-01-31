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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class AuthorizationCodeFlowRequestTests: XCTestCase {
    let configuration = OAuth2Client.Configuration(
        issuerURL: URL(string: "https://example.com")!,
        clientId: "clientid",
        scope: "openid",
        redirectUri: URL(string: "com.example:/redirect"))
    var openIdConfiguration: OpenIdConfiguration!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!
    
    typealias Request = AuthorizationCodeFlow.TokenRequest
    typealias Context = AuthorizationCodeFlow.Context

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        client = OAuth2Client(configuration, session: urlSession)
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
        flow = try AuthorizationCodeFlow(client: client)
    }
    
    func testTokenRequest() throws {
        let context = Context(additionalParameters: ["foo": "bar"])
        let request = try Request(
            openIdConfiguration: openIdConfiguration,
            clientConfiguration: configuration,
            additionalParameters: ["name": "value"],
            context: context,
            authorizationCode: "abc123")
        
        XCTAssertEqual(request.category, .token)
        XCTAssertTrue(request.tokenValidatorContext is Context)
        
        let bodyParameters: [String: String]? = request.bodyParameters?.mapValues(\.stringValue)
        var expected = [
            "grant_type": "authorization_code",
            "code": "abc123",
            "redirect_uri": "com.example:/redirect",
            "name": "value",
            "foo": "bar",
            "scope": "openid",
            "client_id": "clientid",
        ]
        if let pkce = context.pkce {
            expected["code_verifier"] = pkce.codeVerifier
        }
        XCTAssertEqual(bodyParameters, expected)
    }
}
