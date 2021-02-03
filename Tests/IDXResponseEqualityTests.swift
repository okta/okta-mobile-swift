//
//  IDXResponseEqualityTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-03.
//

import XCTest
@testable import OktaIdx

class IDXResponseEqualityTests: XCTestCase {
    func testContextEquality() {
        let compare = IDXClient.Context(interactionHandle: "handle",
                                       codeVerifier: "verifier")
        XCTAssertNotEqual(compare as NSObject, "Foo" as NSObject)

        var object = IDXClient.Context(interactionHandle: "handle2",
                                       codeVerifier: "verifier2")
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Context(interactionHandle: "handle",
                                       codeVerifier: "verifier2")
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Context(interactionHandle: "handle",
                                       codeVerifier: "verifier")
        XCTAssertEqual(compare, object)
    }

    func testTokenEquality() throws {
        let compare = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type")
        XCTAssertNotEqual(compare as NSObject, "Foo" as NSObject)

        var object = IDXClient.Token(accessToken: "access2",
                                     refreshToken: "refresh2",
                                     expiresIn: 100,
                                     idToken: "foo2",
                                     scope: "bar2",
                                     tokenType: "type2")
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Token(accessToken: "access",
                                     refreshToken: nil,
                                     expiresIn: 10,
                                     idToken: nil,
                                     scope: "bar",
                                     tokenType: "type")
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Token(accessToken: "access",
                                 refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type")
        XCTAssertEqual(compare, object)
    }
}
