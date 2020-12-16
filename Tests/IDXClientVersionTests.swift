//
//  IdentityEngineTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-08.
//

import XCTest
@testable import OktaIdx

class IDXClientVersionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVersionEnum() throws {
        var value: IDXClient.Version? = nil
            
        value = .v1_0_0
        XCTAssertEqual(value?.rawValue, "1.0.0")
        
        value = IDXClient.Version(rawValue: "1.0.0")
        XCTAssertEqual(value, .v1_0_0)
        
        XCTAssertEqual(IDXClient.Version.latest,
                       .v1_0_0)
        
        let configuration = IDXClient.Configuration(issuer: "foo", clientId: "bar", clientSecret: "baz", scopes: ["boo"], redirectUri: "woo")
        let api = IDXClient.Version.v1_0_0.clientImplementation(with: configuration)
        XCTAssertTrue(type(of: api) == IDXClient.APIVersion1.self)
        
        XCTAssertNil(IDXClient.Version.init(rawValue: "invalid-version"))
    }
}
