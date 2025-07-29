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

#if os(Linux)
import FoundationNetworking
#endif

struct MockApiParsingContext: @unchecked Sendable, APIParsingContext {
    var codingUserInfo: [CodingUserInfoKey : Any]?
    
    let result: APIResponseResult?
    
    func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        result ?? APIResponseResult(statusCode: response.statusCode)
    }
}

@Suite("API Client tests")
struct APIClientTests {
    let baseUrl: URL
    let configuration: OAuth2Client.Configuration
    
    init() throws {
        baseUrl = try #require(URL(string: "https://example.okta.com/oauth2/v1/token"))
        configuration = OAuth2Client.Configuration(issuerURL: baseUrl,
                                                   clientId: "clientid",
                                                   scope: "openid")
    }

    @Test("Override request result status")
    func testOverrideRequestResult() async throws {
        let client = MockApiClient(configuration: configuration,
                                   baseURL: baseUrl,
                                   shouldRetry: .doNotRetry)

        client.mockSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 400,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "Fri, 09 Sep 2022 02:22:14 GMT",
                                         "x-okta-request-id": UUID().uuidString])
        
        let apiRequest = MockApiRequest(url: baseUrl)
        let context = MockApiParsingContext(result: .success)

        let response = try await apiRequest.send(to: client, parsing: context)
        #expect(response.statusCode == 400)
    }
}
