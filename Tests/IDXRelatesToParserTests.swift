//
//  IDXRelatesToParserTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-01-26.
//

import XCTest
@testable import OktaIdx

class IDXRelatesToParserTests: XCTestCase {
    typealias RelatesTo = IDXClient.APIVersion1.Response.RelatesTo
    struct Object: Decodable {
        let relatesTo: RelatesTo
    }
    
    func testEnum() throws {
        XCTAssertEqual(RelatesTo.Path(string: "$"), .root)
        XCTAssertEqual(RelatesTo.Path(string: "authenticatorEnrollments"), .property(name: "authenticatorEnrollments"))
        XCTAssertEqual(RelatesTo.Path(string: "5"), .array(index: 5))
    }
    
    func testSimplePath() throws {
        let string = """
        {"relatesTo":"$.authenticator.value[0]"}
        """
        let value = try JSONDecoder().decode(Object.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(value.relatesTo.path.count, 4)
        XCTAssertEqual(value.relatesTo.path[0], .root)
        XCTAssertEqual(value.relatesTo.path[1], .property(name: "authenticator"))
        XCTAssertEqual(value.relatesTo.path[2], .property(name: "value"))
        XCTAssertEqual(value.relatesTo.path[3], .array(index: 0))
    }
}
