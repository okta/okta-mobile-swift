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

import XCTest
@testable import AuthFoundation
@testable import TestCommon

final class DefaultTimeCoordinatorTests: XCTestCase {
    var coordinator: DefaultTimeCoordinator!
    var client: MockApiClient!
    let baseUrl = URL(string: "https://example.okta.com/oauth2/default")!
    var configuration: OAuth2Client.Configuration!
    let urlSession = URLSessionMock()

    override func setUpWithError() throws {
        coordinator = DefaultTimeCoordinator()
        Date.coordinator = coordinator

        configuration = OAuth2Client.Configuration(baseURL: baseUrl,
                                                   clientId: "clientid",
                                                   scopes: "openid")
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: baseUrl)
    }
    
    override func tearDownWithError() throws {
        DefaultTimeCoordinator.resetToDefault()
        coordinator = nil
    }
    
    func testDateAdjustments() throws {
        XCTAssertEqual(coordinator.offset, 0)

        try sendRequest(offset: 1000, cachePolicy: .returnCacheDataElseLoad)
        XCTAssertEqual(coordinator.offset, 0)
        XCTAssertEqual(coordinator.now.timeIntervalSinceReferenceDate,
                       Date().timeIntervalSinceReferenceDate,
                       accuracy: 2)

        // Test negative clock drift (local clock is slower than the server)
        try sendRequest(offset: 1000, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        XCTAssertEqual(coordinator.offset, 1000, accuracy: 10)
        XCTAssertEqual(coordinator.now.timeIntervalSinceReferenceDate,
                       Date().timeIntervalSinceReferenceDate + 1000,
                       accuracy: 10)
        XCTAssertEqual(coordinator.date(from: Date(timeIntervalSinceNow: 500)).timeIntervalSinceReferenceDate,
                       Date().timeIntervalSinceReferenceDate + 1500,
                       accuracy: 2)

        // Test positive clock drift (local clock is faster than the server)
        try sendRequest(offset: -1000, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        XCTAssertEqual(coordinator.offset, -1000, accuracy: 10)
        XCTAssertEqual(coordinator.now.timeIntervalSinceReferenceDate,
                       Date().timeIntervalSinceReferenceDate - 1000,
                       accuracy: 2)
        XCTAssertEqual(coordinator.date(from: Date(timeIntervalSinceNow: 500)).timeIntervalSinceReferenceDate,
                       Date().timeIntervalSinceReferenceDate - 500,
                       accuracy: 2)
    }
    
    func sendRequest(offset: TimeInterval, cachePolicy: URLRequest.CachePolicy) throws { 
        let newDate = Date(timeIntervalSinceNow: offset)
        let newDateString = httpDateFormatter.string(from: newDate)
        
        let url = try XCTUnwrap(URL(string: "https://example.com/oauth2/v1/token"))
        let request = URLRequest(url: url, cachePolicy: cachePolicy)
        let response = try XCTUnwrap(HTTPURLResponse(url: url,
                                                     statusCode: 200,
                                                     httpVersion: "http/1.1",
                                                     headerFields: [
                                                        "Date": newDateString
                                                     ]))
        
        coordinator.api(client: client, didSend: request, received: response)
    }
}
