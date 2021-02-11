//
//  URLSessionAuditTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-11.
//

import XCTest
@testable import OktaIdx

class URLSessionAuditTests: XCTestCase {
    func testAuditLog() {
        let audit = URLSessionAudit()
        
        XCTAssertEqual(audit.logs.count, 0)
        
        let url = URL(string: "https://example.com/foo")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: "1.1",
                                       headerFields: [ "foo": "bar" ])
        let data = "Response".data(using: .utf8)
        
        audit.add(log: .init(with: request, response: response, body: data))
        
        let addExpectation = expectation(description: "Wait for the item to be added")
        audit.queue.sync {
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 1)
        
        XCTAssertEqual(audit.logs.count, 1)
        
        XCTAssertEqual(audit.description, """
            GET https://example.com/foo
            Request Body:
            <no request body>
            Status code: 200
            Response

            """)

        audit.reset()
        XCTAssertEqual(audit.logs.count, 0)
    }
}
