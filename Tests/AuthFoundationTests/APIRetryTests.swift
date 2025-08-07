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

import Foundation
import Testing

@testable import AuthFoundation
@testable import TestCommon

#if canImport(FoundationNetworking)
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

@Suite("API request retry handling", .disabled("Debugging test deadlocks within CI"))
struct APIRetryTests {
    let issuerURL: URL
    var configuration: OAuth2Client.Configuration
    let requestId = UUID().uuidString
    
    init() throws {
        issuerURL = try #require(URL(string: "https://example.okta.com"))
        configuration = OAuth2Client.Configuration(issuerURL: issuerURL,
                                                   clientId: "clientid",
                                                   scope: "openid")
    }
    
    @Test("Should not retry")
    func testShouldNotRetry() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL,
                                   shouldRetry: .doNotRetry)
        try await performRetryRequest(client: client, count: 1)
        
        #expect(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
    }
    
    @Test("Default retry count")
    func testDefaultRetryCount() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)
        try await performRetryRequest(client: client, count: 4)
        
        #expect(client.mockSession.requests.count == 4)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"] == nil)
        if client.mockSession.requests.count == 4 {
            for index in 1..<4 {
                #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"] == "\(index)")
                #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"] == requestId)
            }
        }
    }

    @Test("Success status code")
    func testApiRetryReturnsSuccessStatusCode() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)
        try await performRetryRequest(client: client, count: 1, isSuccess: true)
        
        #expect(client.mockSession.requests.count == 2)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"] == nil)
        #expect(client.mockSession.requests[1].allHTTPHeaderFields?["X-Okta-Retry-Count"] == "1")
        #expect(client.mockSession.requests[1].allHTTPHeaderFields?["X-Okta-Retry-For"] == requestId)
    }
    
    @Test("Custom maximum retry attempt count")
    func testApiRetryUsingMaximumRetryAttempt() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)
        try await performRetryRequest(client: client, count: 3, isSuccess: true)
        
        #expect(client.mockSession.requests.count == 4)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"] == nil)
        for index in 1..<4 {
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"] == "\(index)")
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"] == requestId)
        }
    }
    
    @Test("Custom retry count")
    func testCustomRetryCount() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL,
                                   shouldRetry: .retry(maximumCount: 5))
        
        try await performRetryRequest(client: client, count: 6)
        
        #expect(client.mockSession.requests.count == 6)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"] == nil)
        for index in 1..<6 {
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"] == "\(index)")
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"] == requestId)
        }
    }
    
    @Test("Delegate overrides do not retry")
    func testRetryDelegateDoNotRetry() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)

        let delegate = APIRetryDelegateRecorder()
        delegate.response = .doNotRetry
        client.delegate = delegate
        
        try await performRetryRequest(client: client, count: 1, isSuccess: false)
        
        #expect(delegate.requests.count == 1)
        #expect(client.request?.allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
    }
    
    @Test("Delegate overrides retry")
    func testRetryDelegateRetry() async throws {
        let delegate = APIRetryDelegateRecorder()
        delegate.response = .retry(maximumCount: 5)

        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)
        client.delegate = delegate
        
        try await performRetryRequest(client: client, count: 5, isSuccess: true)

        #expect(delegate.requests.count == 1)
        #expect(client.mockSession.requests.count == 6)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-Count"] == nil)
        #expect(client.mockSession.requests[0].allHTTPHeaderFields?["X-Okta-Retry-For"] == nil)
        for index in 1..<5 {
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-Count"] == "\(index)")
            #expect(client.mockSession.requests[index].allHTTPHeaderFields?["X-Okta-Retry-For"] == requestId)
        }
    }
    
    @Test("API rate limit handling")
    func testApiRateLimit() throws {
        let date = "Fri, 09 Sep 2022 02:22:14 GMT"
        let rateLimit = APIRateLimit(with: ["x-rate-limit-limit": "0",
                                            "x-rate-limit-remaining": "0",
                                            "x-rate-limit-reset": "1662690193",
                                            "Date": date])
        #expect(rateLimit?.delay != nil)
        #expect(rateLimit?.delay == 59.0)
    }
    
    @Test("Missing reset HTTP header")
    func testMissingResetHeader() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: issuerURL)

        client.mockSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 429,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-okta-request-id": requestId])
        
        let apiRequest = MockApiRequest(url: URL(string: "\(issuerURL.absoluteString)/oauth2/v1/token")!)
        let error = await #expect(throws: APIClientError.self) {
            try await apiRequest.send(to: client)
        }
        
        #expect(error == APIClientError.statusCode(429))
    }
    
    func performRetryRequest(client: MockApiClient, count: Int, isSuccess: Bool = false) async throws {
        let apiRequest = MockApiRequest(url: URL(string: "\(issuerURL.absoluteString)/oauth2/v1/token")!)
        let date = "Fri, 09 Sep 2022 02:22:14 GMT"

        for _ in 0..<count {
            client.mockSession.expect("https://example.okta.com/oauth2/v1/token",
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
            client.mockSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"),
                              contentType: "application/json",
                              headerFields: ["Date": "\(date)",
                                             "x-okta-request-id": requestId])
        }

        try await TaskData.$timeIntervalToNanoseconds.withValue(1_000) {
            if isSuccess {
                let response = try await apiRequest.send(to: client)
                #expect(response.requestId == requestId)
            } else {
                let error = await #expect(throws: APIClientError.self) {
                    try await apiRequest.send(to: client)
                }
                
                #expect(error?.errorDescription == APIClientError.statusCode(429).errorDescription)
            }
        }
    }
}
