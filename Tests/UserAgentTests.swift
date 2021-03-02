//
//  UserAgentTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-11.
//

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
