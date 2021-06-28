/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXClientRequestTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://example.com/oauth2/default",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")

    func testInteractRequest() throws {
        let request = IDXClient.APIVersion1.InteractRequest(state: nil, codeChallenge: "ABCEasyas123")
        let urlRequest = request.urlRequest(using: configuration)
        
        XCTAssertNotNil(urlRequest)
        XCTAssertEqual(urlRequest?.httpMethod, "POST")

        let url = urlRequest?.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/oauth2/default/v1/interact")
        
        XCTAssertEqual(urlRequest?.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(urlRequest?.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertNotNil(urlRequest?.allHTTPHeaderFields?["User-Agent"])

        let data = urlRequest?.httpBody?.urlFormEncoded()
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.keys.sorted(), ["client_id", "code_challenge", "code_challenge_method", "redirect_uri", "scope", "state"])
        XCTAssertEqual(data?["client_id"], "clientId")
        XCTAssertEqual(data?["scope"], "all")
        XCTAssertEqual(data?["code_challenge"], "ABCEasyas123")
        XCTAssertEqual(data?["code_challenge_method"], "S256")
        XCTAssertEqual(data?["redirect_uri"], "redirect:/uri")

        // Ensure state is a UUID
        let state = data?["state"]
        XCTAssertNotNil(UUID(uuidString: state!!))
    }
    
    func testInteractRequestWithCustomState() throws {
        let request = IDXClient.APIVersion1.InteractRequest(state: "mystate", codeChallenge: "ABCEasyas123")
        let urlRequest = try XCTUnwrap(request.urlRequest(using: configuration))
        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded())
        XCTAssertEqual(data["state"], "mystate")
    }
    
    func testTokenRequestWithInteractionCode() throws {
        let issuerUrl = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let request = IDXClient.APIVersion1.TokenRequest(issuer: issuerUrl,
                                                         clientId: "MyClientId",
                                                         clientSecret: "SsshItsSecret",
                                                         codeVerifier: "ABCeasyas123",
                                                         grantType: "interaction_code",
                                                         code: "TheInteractionCode")

        let urlRequest = try XCTUnwrap(request.urlRequest(using: configuration))
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let url = try XCTUnwrap(urlRequest.url?.absoluteString)
        XCTAssertEqual(url, "https://example.com/oauth2/default/v1/token")
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertNotNil(urlRequest.allHTTPHeaderFields?["User-Agent"])

        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded())
        XCTAssertEqual(data.keys.sorted(), ["client_id", "client_secret", "code_verifier", "grant_type", "interaction_code"])
        XCTAssertEqual(data["client_id"], "MyClientId")
        XCTAssertEqual(data["client_secret"], "SsshItsSecret")
        XCTAssertEqual(data["code_verifier"], "ABCeasyas123")
        XCTAssertEqual(data["grant_type"], "interaction_code")
        XCTAssertEqual(data["interaction_code"], "TheInteractionCode")
    }

    func testRevokeRequest() throws {
        let request = IDXClient.APIVersion1.RevokeRequest(token: "SsshItsSecret", tokenTypeHint: "access_token")

        let urlRequest = try XCTUnwrap(request.urlRequest(using: configuration))
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let url = try XCTUnwrap(urlRequest.url?.absoluteString)
        XCTAssertEqual(url, "https://example.com/oauth2/v1/revoke")
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertNotNil(urlRequest.allHTTPHeaderFields?["User-Agent"])

        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded())
        XCTAssertEqual(data.keys.sorted(), ["client_id", "token", "token_type_hint"])
        XCTAssertEqual(data["client_id"], "clientId")
        XCTAssertEqual(data["token"], "SsshItsSecret")
        XCTAssertEqual(data["token_type_hint"], "access_token")
    }
}
