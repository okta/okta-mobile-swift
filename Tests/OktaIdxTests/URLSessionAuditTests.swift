/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if targetEnvironment(simulator) && DEBUG
class URLSessionAuditTests: XCTestCase {
    func testAuditLog() {
        let audit = URLSessionAudit()
        
        XCTAssertEqual(audit.logs.count, 0)
        
        let url = URL(string: "https://example.com/foo")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: "1.1",
                                       headerFields: [
                                        "foo": "bar",
                                        "x-okta-request-id": "request123"
                                       ])
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
            Request ID: request123
            Response

            """)

        audit.reset()
        XCTAssertEqual(audit.logs.count, 0)
    }
}
#endif
