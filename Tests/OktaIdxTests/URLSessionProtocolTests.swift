/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

class URLSessionProtocolTests: XCTestCase {
    let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    let responseData = Data()
    let urlResponse = URLResponse()
    let httpSuccessResponse = HTTPURLResponse(url: URL(string: "https://example.com/")!,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: nil)
    let httpFailureResponses = [401: HTTPURLResponse(url: URL(string: "https://example.com/")!,
                                              statusCode: 401,
                                              httpVersion: nil,
                                              headerFields: nil),
                                500: HTTPURLResponse(url: URL(string: "https://example.com/")!,
                                                     statusCode: 500,
                                                     httpVersion: nil,
                                                     headerFields: nil)]

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
        session.handleDataTaskRequest(data: responseData, response: httpFailureResponses[401]!, error: expectedError) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertEqual(response, self.httpFailureResponses[401])
            XCTAssertEqual(error as NSError?, expectedError)
            called = true
        }
        XCTAssertTrue(called)
    }

    func testErrorCodeResponse() {
        var called = false
        session.handleDataTaskRequest(data: responseData, response: httpFailureResponses[500]!, error: nil) {  (data, response, error) in
            XCTAssertEqual(data, self.responseData)
            XCTAssertEqual(response, self.httpFailureResponses[500])
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
