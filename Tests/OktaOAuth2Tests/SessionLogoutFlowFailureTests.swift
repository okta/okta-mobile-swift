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
@testable import APIClientTestCommon
@testable import AuthFoundationTestCommon
@testable import JWT

class SessionLogoutFlowFailureTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let logoutRedirectUri = URL(string: "com.example:/logout")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: SessionLogoutFlow!
    let logoutIDToken = "logoutIDToken"
    let state = "state"
    
    static override func setUp() {
        registerMock(bundles: .oktaOAuth2Tests)
    }
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer, clientId: "clientId", scopes: "openid", session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: nil,
                          error: OAuth2Error.cannotComposeUrl)
        
        flow = SessionLogoutFlow(logoutRedirectUri: logoutRedirectUri, client: client)
    }

    func testDelegate() throws {
        let delegate = SessionLogoutFlowDelegateRecorder()
        flow.add(delegate: delegate)
        
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        XCTAssertNil(delegate.url)
        XCTAssertNil(delegate.error)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let resumeExpection = expectation(description: "Expect success")
        
        try flow.start(with: context) { result in
            XCTAssertTrue(self.flow.inProgress)
            resumeExpection.fulfill()
        }
        
        wait(for: [resumeExpection], timeout: 1)
        
        XCTAssertFalse(flow.inProgress)
        XCTAssertNil(flow.context)
        XCTAssertNotEqual(flow.context, context)
        XCTAssertNil(flow.context?.logoutURL)
        
        XCTAssertNil(delegate.url)
        XCTAssertNotNil(delegate.error)
    }
    
    func testWithBlocks() throws {
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let resumeExpection = expectation(description: "Expect success")
        
        try flow.start(with: context) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            
            XCTAssertTrue(self.flow.inProgress)
            resumeExpection.fulfill()
        }
        
        wait(for: [resumeExpection], timeout: .long)

        XCTAssertFalse(flow.inProgress)
        XCTAssertNil(flow.context)
        XCTAssertNotEqual(flow.context, context)
        XCTAssertNil(flow.context?.logoutURL)
    }
}
