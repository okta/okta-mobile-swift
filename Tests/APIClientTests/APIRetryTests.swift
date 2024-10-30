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
@testable import APIClient
@testable import APIClientTestCommon

#if os(Linux)
import FoundationNetworking
#endif

class APIRetryDelegateRecorder: APIClientDelegate {
    var response: APIRetry?
    private(set) var requests: [URLRequest] = []

    func api(client: any APIClient, shouldRetry request: URLRequest) -> APIRetry {
        requests.append(request)
        return response ?? .default
    }
    
    func reset() {
        response = nil
        requests.removeAll()
    }
}

final class MockAPIClientConfiguration: APIClientConfiguration, Sendable {
    let baseURL: URL
    let clientId: String
    let scopes: String
    
    init(baseURL: URL, clientId: String, scopes: String) {
        self.baseURL = baseURL
        self.clientId = clientId
        self.scopes = scopes
    }
}

//class APIRetryTests: XCTestCase {
//    var client: MockApiClient!
//    let baseUrl = URL(string: "https://example.okta.com/oauth2/v1/token")!
//    var configuration: MockAPIClientConfiguration!
//    let urlSession = URLSessionMock()
//    var apiRequest: MockApiRequest!
//    let requestId = UUID().uuidString
//    
//    override func setUpWithError() throws {
//        configuration = MockAPIClientConfiguration(baseURL: baseUrl,
//                                                   clientId: "clientid",
//                                                   scopes: "openid")
//        client = MockApiClient(configuration: configuration,
//                               session: urlSession,
//                               baseURL: baseUrl)
//        apiRequest = MockApiRequest(url: baseUrl)
//    }
//
//    @MainActor
//    func testShouldNotRetry() throws {
//        client = MockApiClient(configuration: configuration,
//                               session: urlSession,
//                               baseURL: baseUrl,
//                               shouldRetry: .doNotRetry)
//        try performRetryRequest(count: 1)
//        XCTAssertNil(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"])
//    }
//    
//    @MainActor
//    func testDefaultRetryCount() throws {
//        try performRetryRequest(count: 4)
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "3")
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
//    }
//
//    @MainActor
//    func testApiRetryReturnsSuccessStatusCode() throws {
//        try performRetryRequest(count: 1, isSuccess: true)
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "1")
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
//    }
//    
//    @MainActor
//    func testApiRetryUsingMaximumRetryAttempt() throws {
//        try performRetryRequest(count: 3, isSuccess: true)
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "3")
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
//    }
//    
//    @MainActor
//    func testCustomRetryCount() throws {
//        client = MockApiClient(configuration: configuration,
//                               session: urlSession,
//                               baseURL: baseUrl,
//                               shouldRetry: .retry(maximumCount: 5))
//        try performRetryRequest(count: 6)
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "5")
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
//    }
//    
//    @MainActor
//    func testRetryDelegateDoNotRetry() throws {
//        let delegate = APIRetryDelegateRecorder()
//        delegate.response = .doNotRetry
//        client.delegate = delegate
//        
//        try performRetryRequest(count: 1, isSuccess: false)
//        XCTAssertEqual(delegate.requests.count, 1)
//        XCTAssertNil(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"])
//    }
//    
//    @MainActor
//    func testRetryDelegateRetry() throws {
//        let delegate = APIRetryDelegateRecorder()
//        delegate.response = .retry(maximumCount: 5)
//        client.delegate = delegate
//        
//        try performRetryRequest(count: 5, isSuccess: true)
//        XCTAssertEqual(delegate.requests.count, 1)
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"], "5")
//        XCTAssertEqual(client.request?.allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
//    }
//    
//    func testApiRateLimit() throws {
//        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
//        let rateLimit = APIRateLimit(with: ["x-rate-limit-limit": "0",
//                                            "x-rate-limit-remaining": "0",
//                                            "x-rate-limit-reset": "1662690193",
//                                            "Date": date])
//        XCTAssertNotNil(rateLimit?.delay)
//        XCTAssertEqual(rateLimit?.delay, 59.0)
//    }
//    
//    @MainActor
//    func testMissingResetHeader() throws {
//        urlSession.expect("https://example.okta.com/oauth2/v1/token",
//                          data: try data(filename: "token",
//                                         matching: "APIClientTestCommon"),
//                          statusCode: 429,
//                          contentType: "application/json",
//                          headerFields: ["x-rate-limit-limit": "0",
//                                         "x-rate-limit-remaining": "0",
//                                         "x-okta-request-id": requestId])
//        
//        let expect = expectation(description: "network request")
//        apiRequest.send(to: client, completion: { result in
//            guard case .failure(let error) = result else {
//                XCTFail()
//                return
//            }
//            XCTAssertEqual(error.localizedDescription, APIClientError.statusCode(429).localizedDescription)
//            expect.fulfill()
//        })
//        
//        waitForExpectations(timeout: 1.0) { error in
//            XCTAssertNil(error)
//        }
//    }
//    
//    @MainActor
//    func performRetryRequest(count: Int, isSuccess: Bool = false) throws {
//        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
//        for _ in 0..<count {
//            urlSession.expect("https://example.okta.com/oauth2/v1/token",
//                              data: try data(filename: "token",
//                                             matching: "APIClientTestCommon"),
//                              statusCode: 429,
//                              contentType: "application/json",
//                              headerFields: ["x-rate-limit-limit": "0",
//                                             "x-rate-limit-remaining": "0",
//                                             "x-rate-limit-reset": "1609459200",
//                                             "Date": "\(date)",
//                                             "x-okta-request-id": requestId])
//        }
//        
//        if isSuccess {
//            urlSession.expect("https://example.okta.com/oauth2/v1/token",
//                              data: try data(filename: "token",
//                                             matching: "APIClientTestCommon"),
//                              contentType: "application/json",
//                              headerFields: ["Date": "\(date)",
//                                             "x-okta-request-id": requestId])
//        }
//        
//        let expect = expectation(description: "network request")
//        apiRequest.send(to: client, completion: { result in
//            switch result {
//            case .success(let response):
//                XCTAssertNotNil(response)
//                XCTAssertEqual(response.requestId, self.requestId)
//            case .failure(let error):
//                XCTAssertEqual(error.errorDescription, APIClientError.statusCode(429).errorDescription)
//            }
//            expect.fulfill()
//        })
//        waitForExpectations(timeout: 9.0) { error in
//            XCTAssertNil(error)
//        }
//    }
//}
