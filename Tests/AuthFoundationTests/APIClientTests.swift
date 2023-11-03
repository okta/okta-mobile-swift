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

struct MockApiParsingContext: APIParsingContext {
    var codingUserInfo: [CodingUserInfoKey : Any]?
    
    let result: APIResponseResult?
    
    func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        result ?? APIResponseResult(statusCode: response.statusCode)
    }
}

class APIClientTests: XCTestCase {
    var client: MockApiClient!
    let baseUrl = URL(string: "https://example.okta.com/oauth2/v1/token")!
    var configuration: OAuth2Client.Configuration!
    let urlSession = URLSessionMock()
    let requestId = UUID().uuidString
    
    override func setUpWithError() throws {
        configuration = OAuth2Client.Configuration(baseURL: baseUrl,
                                                   clientId: "clientid",
                                                   scopes: "openid")
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: baseUrl)
    }

    func testOverrideRequestResult() throws {
        client = MockApiClient(configuration: configuration,
                               session: urlSession,
                               baseURL: baseUrl,
                               shouldRetry: .doNotRetry)

        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          statusCode: 400,
                          contentType: "application/json",
                          headerFields: ["x-rate-limit-limit": "0",
                                         "x-rate-limit-remaining": "0",
                                         "x-rate-limit-reset": "1609459200",
                                         "Date": "Fri, 09 Sep 2022 02:22:14 GMT",
                                         "x-okta-request-id": requestId])
        
        let apiRequest = MockApiRequest(url: baseUrl)
        let context = MockApiParsingContext(result: .success)

        let expect = expectation(description: "network request")
        apiRequest.send(to: client, parsing: context, completion: { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.statusCode, 400)
            case .failure(_):
                XCTFail("Did not expect the request to fail")
            }
            expect.fulfill()
        })
        waitForExpectations(timeout: 9.0) { error in
            XCTAssertNil(error)
        }
    }
}
