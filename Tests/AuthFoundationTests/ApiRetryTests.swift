//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import XCTest
@testable import AuthFoundation
@testable import TestCommon

class ApiRetryTests: XCTestCase {
    var client: MockApiClient!
    let baseUrl = URL(string: "https://example.okta.com/oauth2/v1/token")!
    var configuration: OAuth2Client.Configuration!
    let urlSession = URLSessionMock()
    var apiRequest: MockApiRequest!

    override func setUpWithError() throws {
        configuration = OAuth2Client.Configuration(baseURL: baseUrl,
                                                   clientId: "clientid",
                                                   scopes: "openid")
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: baseUrl)
        apiRequest = MockApiRequest(url: baseUrl)
    }

    func testShouldNotRetry() throws {
        let date = Date()
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": UUID().uuidString])
        let client = MockApiClient(configuration: configuration,
                                   session: urlSession,
                                   baseURL: baseUrl,
                                   shouldRetry: .doNotRetry)
        
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .failure(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.errorDescription, APIClientError.statusCode(429).errorDescription)
            expect.fulfill()
        })
        
        XCTAssertNil(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"])
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDefaultRetryCount() throws {
        let date = Date()
        let requestId = UUID().uuidString

        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date" : "\(date)",
                                         "x-okta-request-id": requestId])
        
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .failure(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.errorDescription, APIClientError.statusCode(429).errorDescription)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "3")
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
    }

    func testApiRetryReturnsSuccessStatusCode() throws {
        let date = Date()
        let requestId = UUID().uuidString
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
    
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .success(token) = result else {
                XCTFail()
                return
            }
            XCTAssertNotNil(token)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "1")
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
    }
    
    func testNoRequestId() throws {
        let date = Date()
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)"])
        
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .failure(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.errorDescription, APIClientError.noRequestId.errorDescription)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testApiRetryUsingMaximumRetryAttempt() throws {
        let date = Date()
        let requestId = UUID().uuidString
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
    
        
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .success(token) = result else {
                XCTFail()
                return
            }
            XCTAssertNotNil(token)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "3")
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
    }
    
    func testCustomRetryCount() throws {
        let date = Date()
        let requestId = UUID().uuidString
        let client = MockApiClient(configuration: configuration,
                                   session: urlSession,
                                   baseURL: baseUrl,
                                   shouldRetry: .retry(maximumRetryCount: 5))
        
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "\(date)",
                                         "x-okta-request-id": requestId])
        
        let expect = expectation(description: "network request")
        apiRequest.send(to: client, completion: { result in
            guard case let .failure(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.errorDescription, APIClientError.statusCode(429).errorDescription)
            expect.fulfill()
        })
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "5")
        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
    }
    
    func testApiRateLimit() throws {
        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
        let rateLimit = ApiRateLimit(with: ["x-rate-limit-limit": "0",
                                            "x-rate-limit-remaining": "0",
                                            "x-rate-limit-reset": "1662690193",
                                            "Date": date])
        XCTAssertNotNil(rateLimit?.delay)
        XCTAssertEqual(rateLimit?.delay, 59.0)
    }
}
