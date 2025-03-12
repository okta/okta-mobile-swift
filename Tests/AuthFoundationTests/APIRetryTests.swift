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

#if os(Linux)
import FoundationNetworking
#endif

class APIRetryDelegateRecorder: APIClientDelegate, @unchecked Sendable {
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

class APIRetryTests: XCTestCase {
    var client: MockApiClient!
    let issuerURL = URL(string: "https://example.okta.com")!
    var configuration: OAuth2Client.Configuration!
    let urlSession = URLSessionMock()
    var apiRequest: MockApiRequest!
    let requestId = UUID().uuidString
    
    override func setUpWithError() throws {
        configuration = OAuth2Client.Configuration(issuerURL: issuerURL,
                                                   clientId: "clientid",
                                                   scope: "openid")
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: issuerURL)
        apiRequest = MockApiRequest(url: URL(string: "\(issuerURL.absoluteString)/oauth2/v1/token")!)
        
        _APIClientRetryDelayTimeIntervalToNanoseconds.wrappedValue = 1_000
    }

    override func tearDownWithError() throws {
        _APIClientRetryDelayTimeIntervalToNanoseconds.wrappedValue = 1_000_000_000
    }
    
    func testShouldNotRetry() async throws {
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: issuerURL,
                               shouldRetry: .doNotRetry)
        try await performRetryRequest(count: 1)
        XCTAssertNil(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"])
    }
    
    func testDefaultRetryCount() async throws {
        try await performRetryRequest(count: 4)
        
        XCTAssertEqual(urlSession.requests.count, 4)
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"])
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"])
        for index in 1..<4 {
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"], "\(index)")
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
        }
    }

    func testApiRetryReturnsSuccessStatusCode() async throws {
        try await performRetryRequest(count: 1, isSuccess: true)
        XCTAssertEqual(urlSession.requests.count, 2)
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"])
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"])
        XCTAssertEqual(urlSession.requests[1].allHTTPHeaderFields?["X-Okta-Retry-Count"], "1")
        XCTAssertEqual(urlSession.requests[1].allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
    }
    
    func testApiRetryUsingMaximumRetryAttempt() async throws {
        try await performRetryRequest(count: 3, isSuccess: true)
        XCTAssertEqual(urlSession.requests.count, 4)
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"])
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"])
        for index in 1..<4 {
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"], "\(index)")
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
        }
    }
    
    func testCustomRetryCount() async throws {
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: issuerURL,
                               shouldRetry: .retry(maximumCount: 5))
        try await performRetryRequest(count: 6)
        XCTAssertEqual(urlSession.requests.count, 6)
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"])
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"])
        for index in 1..<6 {
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"], "\(index)")
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
        }
    }
    
    func testRetryDelegateDoNotRetry() async throws {
        let delegate = APIRetryDelegateRecorder()
        delegate.response = .doNotRetry
        client.delegate = delegate
        
        try await performRetryRequest(count: 1, isSuccess: false)
        XCTAssertEqual(delegate.requests.count, 1)
        XCTAssertNil(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"])
    }
    
    func testRetryDelegateRetry() async throws {
        let delegate = APIRetryDelegateRecorder()
        delegate.response = .retry(maximumCount: 5)
        client.delegate = delegate
        
        try await performRetryRequest(count: 5, isSuccess: true)
        XCTAssertEqual(delegate.requests.count, 1)
        XCTAssertEqual(urlSession.requests.count, 6)
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"])
        XCTAssertNil(urlSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"])
        for index in 1..<5 {
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"], "\(index)")
            XCTAssertEqual(urlSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"], requestId)
        }
    }
    
    func testApiRateLimit() throws {
        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
        let rateLimit = APIRateLimit(with: ["x-rate-limit-limit": "0",
                                            "x-rate-limit-remaining": "0",
                                            "x-rate-limit-reset": "1662690193",
                                            "Date": date])
        XCTAssertNotNil(rateLimit?.delay)
        XCTAssertEqual(rateLimit?.delay, 59.0)
    }
    
    func testMissingResetHeader() async throws {
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-okta-request-id": requestId])
        
        await XCTAssertThrowsErrorAsync(try await apiRequest.send(to: client)) { error in
            XCTAssertEqual(error.localizedDescription, APIClientError.statusCode(429).localizedDescription)
        }
    }
    
    func performRetryRequest(count: Int, isSuccess: Bool = false) async throws {
        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
        for _ in 0..<count {
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"),
                              statusCode: 429,
                              contentType: "application/json",
                              headerFields: ["x-rate-limit-limit": "0",
                                             "x-rate-limit-remaining": "0",
                                             "x-rate-limit-reset": "1609459200",
                                             "Date": "\(date)",
                                             "x-okta-request-id": requestId])
        }
        
        if isSuccess {
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"),
                              contentType: "application/json",
                              headerFields: ["Date": "\(date)",
                                             "x-okta-request-id": requestId])
        }
        
        if isSuccess {
            let response = try await apiRequest.send(to: client)
            XCTAssertNotNil(response)
            XCTAssertEqual(response.requestId, self.requestId)
        } else {
            await XCTAssertThrowsErrorAsync(try await apiRequest.send(to: client)) { error in
                let error = error as? APIClientError
                XCTAssertEqual(error?.errorDescription, APIClientError.statusCode(429).errorDescription)
            }
        }
    }
}
