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

class SessionLogoutFlowDelegateRecorder: SessionLogoutFlowDelegate {
    var error: OAuth2Error?
    var url: URL?
    let fragment = "customizedUrl"
    
    func logout<Flow>(flow: Flow, shouldLogoutUsing url: URL) where Flow : SessionLogoutFlow {
        self.url = url
    }
    
    func logout<SessionLogoutFlow>(flow: SessionLogoutFlow, received error: OAuth2Error) {
        self.error = error
    }
    
    func logout<SessionLogoutFlow>(flow: SessionLogoutFlow, customizeUrl urlComponents: inout URLComponents) {
        urlComponents.fragment = fragment
    }
}

final class SessionLogoutFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let logoutRedirectUri = URL(string: "com.example:/logout")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: SessionLogoutFlow!
    let logoutIDToken = "logoutIDToken"
    let state = "state"
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer, clientId: "clientId", scopes: "openid", session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = SessionLogoutFlow(logoutRedirectUri: logoutRedirectUri, client: client)
    }
    
    func testWithDelegate() throws {
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
            XCTAssertNotEqual(self.flow.context, context)
            XCTAssertEqual(self.flow.context?.state, context.state)
            resumeExpection.fulfill()
        }
        
        wait(for: [resumeExpection], timeout: 1)

        XCTAssertEqual(delegate.url?.absoluteString, """
                            https://example.okta.com/oauth2/v1/logout\
                            ?id_token_hint=\(logoutIDToken)\
                            &post_logout_redirect_uri=\(logoutRedirectUri.absoluteString)\
                            &state=\(state)\
                            #\(delegate.fragment)
                            """)
        XCTAssertNil(delegate.error)
        
        XCTAssertFalse(flow.inProgress)
    }
    
    func testWithBlocks() throws {
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let resumeExpection = expectation(description: "Expect success")
        
        try flow.start(with: context) { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url, self.flow.context?.logoutURL)
            case .failure:
                XCTFail()
            }
            
            XCTAssertTrue(self.flow.inProgress)
            
            let newContext = self.flow.context
            XCTAssertNotEqual(newContext, context)
            XCTAssertEqual(newContext?.state, context.state)
            XCTAssertNotNil(newContext?.logoutURL)
            XCTAssertEqual(newContext?.logoutURL?.absoluteString, """
                                https://example.okta.com/oauth2/v1/logout\
                                ?id_token_hint=\(self.logoutIDToken)\
                                &post_logout_redirect_uri=\(self.logoutRedirectUri.absoluteString)\
                                &state=\(self.state)
                                """)
            resumeExpection.fulfill()
        }
        
        wait(for: [resumeExpection], timeout: 1)

        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
    }

    func testPromptWithBlocks() throws {
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let resumeExpection = expectation(description: "Expect success")
        
        try flow.start(with: context, additionalParameters: ["prompt": "login"]) { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url.absoluteString, """
                               https://example.okta.com/oauth2/v1/logout\
                               ?id_token_hint=\(self.logoutIDToken)\
                               &prompt=login\
                               &state=\(self.state)
                               """)
            case .failure:
                XCTFail()
            }

            resumeExpection.fulfill()
        }
        
        wait(for: [resumeExpection], timeout: 1)
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testWithAsync() async throws {
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.inProgress)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        
        let logoutUrl = try await flow.start(with: context)
        
        XCTAssertNotEqual(flow.context, context)
        XCTAssertEqual(logoutUrl.absoluteString, """
                            https://example.okta.com/oauth2/v1/logout\
                            ?id_token_hint=\(logoutIDToken)\
                            &post_logout_redirect_uri=\(logoutRedirectUri.absoluteString)\
                            &state=\(state)
                            """)
    }
    #endif
}
