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

#if !SWIFT_PACKAGE
class UserAgentTests: XCTestCase {
    var regex: NSRegularExpression!
    
    override func setUpWithError() throws {
        let pattern = "okta-idx-swift/[\\d\\.]+ xctest/[\\d+\\.]+ CFNetwork/[\\d+\\.]+ Device/\\S+ (iOS|watchOS|tvOS|macOS)/[\\d\\.]+"
        regex = try NSRegularExpression(pattern: pattern, options: [])
    }
    
    func regexMatch(in userAgent: String?) -> NSTextCheckingResult? {
        guard let userAgent = userAgent else { return nil }
        
        let range = NSRange(location: 0, length: userAgent.count)
        return regex.firstMatch(in: userAgent, options: [], range: range)
    }
    
    func testUserAgent() throws {
        let userAgent = buildUserAgent()
        XCTAssertNotNil(userAgent)
        
        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }
    
    func testInteractRequest() {
        let request = IDXClient.APIVersion1.InteractRequest(state: nil, codeChallenge: "challenge")
        let userAgent = request.httpHeaders["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }

    func testIntrospectRequest() {
        let request = IDXClient.APIVersion1.IntrospectRequest(interactionHandle: "abc123")
        let userAgent = request.httpHeaders["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }
    
    func testTokenRequest() {
        let request = IDXClient.APIVersion1.TokenRequest(method: "POST",
                                                         href: URL(string: "https://example.com")!,
                                                         accepts: .formEncoded,
                                                         parameters: [:])
        let userAgent = request.httpHeaders["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }

    func testRemediationRequest() {
        let request = IDXClient.APIVersion1.RemediationRequest(method: "POST",
                                                               href: URL(string: "https://example.com")!,
                                                               accepts: .formEncoded,
                                                               parameters: [:])
        let userAgent = request.httpHeaders["User-Agent"]
        XCTAssertNotNil(userAgent)

        let match = regexMatch(in: userAgent)
        XCTAssertNotNil(match)
    }
}
#endif
