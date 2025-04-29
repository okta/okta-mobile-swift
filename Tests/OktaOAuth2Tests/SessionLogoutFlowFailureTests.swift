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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

class SessionLogoutFlowFailureTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let logoutRedirectUri = URL(string: "com.example:/logout")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    let logoutIDToken = "logoutIDToken"
    let state = "state"
    
    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid",
                              redirectUri: redirectUri,
                              logoutRedirectUri: logoutRedirectUri,
                              session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: nil,
                          error: OAuth2Error.cannotComposeUrl)
    }

    func testDelegate() async throws {
        let flow = client.sessionLogoutFlow()
        let delegate = SessionLogoutFlowDelegateRecorder()
        flow.add(delegate: delegate)

        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        XCTAssertNil(delegate.url)
        XCTAssertNil(delegate.error)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let error = await XCTAssertThrowsErrorAsync(try await flow.start(with: context))

        XCTAssertFalse(flow.inProgress)
        XCTAssertNotNil(flow.context)
        XCTAssertEqual(flow.context, context)
        XCTAssertNil(flow.context?.logoutURL)

        await MainActor.yield()
        XCTAssertNil(delegate.url)
        XCTAssertEqual(error as? OAuth2Error, OAuth2Error.cannotComposeUrl)
        XCTAssertNotNil(delegate.error)
    }

    func testWithBlocks() async throws {
        let flow = client.sessionLogoutFlow()
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)

        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let expectation = expectation(description: "Expect success")
        flow.start(with: context) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertFalse(flow.inProgress)
        XCTAssertNotNil(flow.context)
        XCTAssertEqual(flow.context, context)
        XCTAssertNil(flow.context?.logoutURL)
    }
}
