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
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid",
                              redirectUri: redirectUri,
                              logoutRedirectUri: logoutRedirectUri,
                              session: urlSession)
        
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = SessionLogoutFlow(client: client)
    }
    
    func testWithDelegate() async throws {
        let delegate = SessionLogoutFlowDelegateRecorder()
        flow.add(delegate: delegate)
        
        await XCTAssertNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.inProgress)
        XCTAssertNil(delegate.url)
        XCTAssertNil(delegate.error)
        
        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let url = try await flow.start(with: context)
        XCTAssertEqual(url.absoluteString, """
                            https://example.okta.com/oauth2/v1/logout\
                            ?client_id=clientId\
                            &id_token_hint=\(logoutIDToken)\
                            &post_logout_redirect_uri=\(logoutRedirectUri.absoluteString)\
                            &state=\(state)\
                            #\(delegate.fragment)
                            """)
        XCTAssertEqual(delegate.url, url)
        XCTAssertNil(delegate.error)
        
        await XCTAssertFalseAsync(await flow.inProgress)
    }

    func testWithBlocks() async throws {
        await XCTAssertNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.inProgress)

        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        let resumeExpection = expectation(description: "Expect success")
        
        flow.start(with: context) { result in
            Task {
                switch result {
                case .success(let url):
                    let logoutURL = await self.flow.context?.logoutURL
                    XCTAssertEqual(url, logoutURL)
                case .failure:
                    XCTFail()
                }

                let newContext = await self.flow.context
                XCTAssertEqual(newContext?.state, context.state)
                XCTAssertNotNil(newContext?.logoutURL)
                XCTAssertEqual(newContext?.logoutURL?.absoluteString, """
                                https://example.okta.com/oauth2/v1/logout\
                                ?client_id=clientId\
                                &id_token_hint=\(self.logoutIDToken)\
                                &post_logout_redirect_uri=\(self.logoutRedirectUri.absoluteString)\
                                &state=\(self.state)
                                """)
                resumeExpection.fulfill()
            }
        }
        await fulfillment(of: [resumeExpection], timeout: 1)

        let newOptionalContext = await flow.context
        let newContext = try XCTUnwrap(newOptionalContext)
        XCTAssertNotEqual(newContext.logoutURL, context.logoutURL)
        await XCTAssertFalseAsync(await flow.inProgress)
    }

    func testPromptAsync() async throws {
        await XCTAssertNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.inProgress)

        let context = SessionLogoutFlow.Context(idToken: logoutIDToken,
                                                state: state,
                                                additionalParameters: ["prompt": "login"])
        let url = try await flow.start(with: context)
        XCTAssertEqual(url.absoluteString, """
                               https://example.okta.com/oauth2/v1/logout\
                               ?client_id=clientId\
                               &id_token_hint=\(self.logoutIDToken)\
                               &prompt=login\
                               &state=\(self.state)
                               """)
    }
    
    func testWithAsync() async throws {
        await XCTAssertNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.inProgress)

        let context = SessionLogoutFlow.Context(idToken: logoutIDToken, state: state)
        
        let logoutUrl = try await flow.start(with: context)
        try await XCTAssertEqualAsync(logoutUrl, await self.flow.context?.logoutURL)

        let newContext = await flow.context
        XCTAssertNotEqual(newContext?.logoutURL, context.logoutURL)
        await XCTAssertFalseAsync(await flow.inProgress)
        XCTAssertNotEqual(newContext?.logoutURL, context.logoutURL)
        XCTAssertEqual(logoutUrl.absoluteString, """
                            https://example.okta.com/oauth2/v1/logout\
                            ?client_id=clientId\
                            &id_token_hint=\(logoutIDToken)\
                            &post_logout_redirect_uri=\(logoutRedirectUri.absoluteString)\
                            &state=\(state)
                            """)
    }
}
