//
//  PKCETests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import XCTest
@testable import OktaIdx

class PKCETests: XCTestCase {
    func testSha256() {
        let codeVerifier = String.pkceCodeVerifier()
        XCTAssertNotNil(codeVerifier)
        XCTAssertTrue(codeVerifier!.isBase64URLEncoded())
        
        let challenge = codeVerifier?.pkceCodeChallenge()
        XCTAssertNotNil(challenge)
        XCTAssertTrue(challenge!.isBase64URLEncoded())
    }
}
