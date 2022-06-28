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
@testable import TestCommon

class UserAgentTests: XCTestCase {
    var regex: NSRegularExpression!
    var issuer: URL!
    var redirectUri: URL!
    var client: OAuth2Client!
    var flow: InteractionCodeFlow!
    let urlSession = URLSessionMock()

    override func setUpWithError() throws {
        issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        flow = InteractionCodeFlow(redirectUri: redirectUri, client: client)

        let pattern = "okta-authfoundation-swift/[\\d\\.]+ okta-idx-swift/[\\d\\.]+ (iOS|watchOS|tvOS|macOS|linux)/[\\d\\.]+ Device/\\S+"
        regex = try NSRegularExpression(pattern: pattern, options: [])
    }
    
    func regexMatch(in userAgent: String?) -> NSTextCheckingResult? {
        guard let userAgent = userAgent else { return nil }
        
        let range = NSRange(location: 0, length: userAgent.count)
        return regex.firstMatch(in: userAgent, options: [], range: range)
    }
    
    func testInteractRequest() throws {
        let request = InteractionCodeFlow.InteractRequest(baseURL: issuer,
                                                          clientId: "ClientId",
                                                          scope: "all",
                                                          redirectUri: redirectUri,
                                                          options: nil,
                                                          pkce: PKCE()!)
        let urlRequest = try request.request(for: client)
        let userAgent = urlRequest.allHTTPHeaderFields?["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }

    func testIntrospectRequest() throws {
        let request = try InteractionCodeFlow.IntrospectRequest(baseURL: issuer,
                                                                interactionHandle: "abc123")
        let urlRequest = try request.request(for: client)
        let userAgent = urlRequest.allHTTPHeaderFields?["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }
    
    func testRemediationRequest() throws {
        let request = InteractionCodeFlow.RemediationRequest(httpMethod: .post,
                                                             url: issuer,
                                                             contentType: nil,
                                                             bodyParameters: nil)
        let urlRequest = try request.request(for: client)
        let userAgent = urlRequest.allHTTPHeaderFields?["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }
}
