//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@Suite("Default time coordinator")
struct DefaultTimeCoordinatorTests {
    let client: MockApiClient
    
    init() throws {
        let baseUrl = try #require(URL(string: "https://example.okta.com/oauth2/default"))
        let configuration = OAuth2Client.Configuration(
            issuerURL: baseUrl,
            clientId: "clientid",
            scope: "openid")
        
        client = MockApiClient(configuration: configuration,
                               baseURL: baseUrl)
    }
    
    @Test("Date offset adjustments", .timeCoordinator)
    func testDateAdjustments() throws {
        let coordinator = try #require(Date.coordinator as? DefaultTimeCoordinator)
        #expect(coordinator.offset == 0)

        try sendRequest(offset: 1000, cachePolicy: .returnCacheDataElseLoad)
        #expect(coordinator.offset == 0)
        #expect(coordinator
            .now
            .timeIntervalSinceReferenceDate
            .is(Date().timeIntervalSinceReferenceDate, accuracy: 2))

        // Test negative clock drift (local clock is slower than the server)
        try sendRequest(offset: 1000, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        #expect(coordinator.offset.is(1000, accuracy: 1))
        #expect(coordinator
            .now
            .timeIntervalSinceReferenceDate
            .is(Date().timeIntervalSinceReferenceDate + 1000, accuracy: 10))
        #expect(coordinator
            .date(from: Date(timeIntervalSinceNow: 500))
            .timeIntervalSinceReferenceDate
            .is(Date().timeIntervalSinceReferenceDate + 1500, accuracy: 2))
        
        // Test positive clock drift (local clock is faster than the server)
        try sendRequest(offset: -1000, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        #expect(coordinator.offset.is(-1000, accuracy: 10))
        #expect(coordinator
            .now
            .timeIntervalSinceReferenceDate
            .is(Date().timeIntervalSinceReferenceDate - 1000, accuracy: 2))
        #expect(coordinator
            .date(from: Date(timeIntervalSinceNow: 500))
            .timeIntervalSinceReferenceDate
            .is(Date().timeIntervalSinceReferenceDate - 500, accuracy: 2))
    }
    
    func sendRequest(offset: TimeInterval, cachePolicy: URLRequest.CachePolicy) throws { 
        let newDate = Date(timeIntervalSinceNow: offset)
        let newDateString = httpDateFormatter.string(from: newDate)
        
        let url = try #require(URL(string: "https://example.com/oauth2/v1/token"))
        let request = URLRequest(url: url, cachePolicy: cachePolicy)
        let response = try #require(HTTPURLResponse(url: url,
                                                    statusCode: 200,
                                                    httpVersion: "http/1.1",
                                                    headerFields: [
                                                        "Date": newDateString
                                                    ]))
        
        let coordinator = try #require(Date.coordinator as? DefaultTimeCoordinator)
        coordinator.api(client: client, didSend: request, received: response)
    }
}
