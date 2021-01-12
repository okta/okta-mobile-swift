//
//  IDXClientAPIVersion1AcceptTypeTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-29.
//

import XCTest
@testable import OktaIdx

class IDXClientAPIVersion1AcceptTypeTests: XCTestCase {
    func testInvalid() {
        XCTAssertNil(IDXClient.APIVersion1.AcceptType(rawValue: "foo"))
    }
    
    func testFormEncoded() throws {
        let type = IDXClient.APIVersion1.AcceptType(rawValue: "application/x-www-form-urlencoded")
        XCTAssertEqual(type, .formEncoded)
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "foo=bar".data(using: .utf8))
        XCTAssertThrowsError(try type?.encodedData(with: ["foo": 1]))
        XCTAssertEqual(type?.stringValue(), "application/x-www-form-urlencoded")
    }
    
    func testIonJson() throws {
        var type = IDXClient.APIVersion1.AcceptType(rawValue: "application/ion+json")
        XCTAssertEqual(type?.stringValue(), "application/ion+json")
        XCTAssertEqual(type, .ionJson(version: nil))
        
        type = IDXClient.APIVersion1.AcceptType(rawValue: "application/ion+json; okta-version=1.0.0")
        XCTAssertEqual(type?.stringValue(), "application/ion+json; okta-version=1.0.0")

        XCTAssertEqual(type, .ionJson(version: "1.0.0"))
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "{\"foo\":\"bar\"}".data(using: .utf8))
    }

    func testJson() throws {
        var type = IDXClient.APIVersion1.AcceptType(rawValue: "application/json")
        XCTAssertEqual(type?.stringValue(), "application/json")
        XCTAssertEqual(type, .json(version: nil))
        
        type = IDXClient.APIVersion1.AcceptType(rawValue: "application/json; okta-version=1.0.0")
        XCTAssertEqual(type?.stringValue(), "application/json; okta-version=1.0.0")

        XCTAssertEqual(type, .json(version: "1.0.0"))
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "{\"foo\":\"bar\"}".data(using: .utf8))
    }
}
