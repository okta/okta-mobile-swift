//
//  URLSessionProtocolTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-17.
//

import XCTest
@testable import OktaIdx

class URLSessionProtocolTests: XCTestCase {
    let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    let responseData = Data()
    let urlResponse = URLResponse()
    let httpSuccessResponse = HTTPURLResponse(url: URL(string: "https://example.com/")!,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: nil)
    let httpFailureResponse = HTTPURLResponse(url: URL(string: "https://example.com/")!,
                                              statusCode: 401,
                                              httpVersion: nil,
                                              headerFields: nil)

    func testDataTaskWithRequest() {
        var called = false
        session.handleDataTaskRequest(data: responseData, response: httpSuccessResponse, error: nil) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertEqual(response, self.httpSuccessResponse)
            XCTAssertNil(error)
            called = true
        }
        XCTAssertTrue(called)
    }

    func testBadResponse() {
        var called = false
        session.handleDataTaskRequest(data: responseData, response: urlResponse, error: nil) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertNil(response)
            XCTAssertTrue(error is IDXClientError)
            XCTAssertEqual(error as? IDXClientError, .invalidHTTPResponse)
            called = true
        }
        XCTAssertTrue(called)
    }

    func testHTTPErrorResponse() {
        var called = false
        let expectedError = NSError(domain: "Foo", code: 1, userInfo: nil)
        session.handleDataTaskRequest(data: responseData, response: httpFailureResponse, error: expectedError) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertEqual(response, self.httpFailureResponse)
            XCTAssertEqual(error as NSError?, expectedError)
            called = true
        }
        XCTAssertTrue(called)
    }

    func testErrorCodeResponse() {
        var called = false
        session.handleDataTaskRequest(data: responseData, response: httpFailureResponse, error: nil) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertEqual(response, self.httpFailureResponse)
            XCTAssertTrue(error is IDXClientError)
            XCTAssertEqual(error as? IDXClientError, .invalidHTTPResponse)
            called = true
        }
        XCTAssertTrue(called)
    }

    func testFormEncodedString() {
        XCTAssertEqual(URLRequest.idxURLFormEncodedString(for: ["foo": "bar", "baz": "boo"]),
                       "baz=boo&foo=bar")
        XCTAssertEqual(URLRequest.idxURLFormEncodedString(for: ["key with &=": "replaced"]),
                       "key+with+%26%3D=replaced")
    }
}
