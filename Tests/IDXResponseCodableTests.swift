//
//  IDXResponseCodableTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-03.
//

import XCTest
@testable import OktaIdx

class IDXResponseCodableTests: XCTestCase {
    func testContextCodable() throws {
        let object = IDXClient.Context(interactionHandle: "handle",
                                       codeVerifier: "verifier")
        let data = try JSONEncoder().encode(object)
        let result = try JSONDecoder().decode(IDXClient.Context.self, from: data)
        XCTAssertEqual(object, result)
    }

    func testTokenCodable() throws {
        let object = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type")
        let data = try JSONEncoder().encode(object)
        let result = try JSONDecoder().decode(IDXClient.Token.self, from: data)
        XCTAssertEqual(object, result)
    }

    func testContextSecureCoding() throws {
        let object = IDXClient.Context(interactionHandle: "handle",
                                       codeVerifier: "verifier")
        let data = try NSKeyedArchiver.archivedData(withRootObject: object,
                                                    requiringSecureCoding: true)
        let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? IDXClient.Context
        XCTAssertEqual(object, result)
    }

    func testTokenSecureCoding() throws {
        let object = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type")
        let data = try NSKeyedArchiver.archivedData(withRootObject: object,
                                                    requiringSecureCoding: true)
        let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? IDXClient.Token
        XCTAssertEqual(object, result)
    }
}
