/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXAuthenticationFlowTests: XCTestCase {
    var issuer: URL!
    var client: OAuth2Client!
    var urlSession: URLSessionMock!
    var redirectUri: URL!
    var flow: IDXAuthenticationFlow!
    var context: IDXAuthenticationFlow.Context!
    var delegate: DelegateRecorder!

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        flow = IDXAuthenticationFlow(redirectUri: redirectUri, client: client)
        context = try IDXAuthenticationFlow.Context(interactionHandle: "interactionHandle", state: "state")

        delegate = DelegateRecorder()
        flow.add(delegate: delegate)
    }
    
    func testStartSuccess() throws {
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow.redirectUri, redirectUri)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNil(flow.context)
        
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        
        let wait = expectation(description: "start")
        flow.start { result in
            defer { wait.fulfill() }
            
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                return
            }
            
            XCTAssertNotNil(response.remediations[.identify])
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(flow.isAuthenticating)

        let context = try XCTUnwrap(flow.context)
        XCTAssertNotNil(context.state)
        XCTAssertEqual(context.interactionHandle, "003Q14X7li")

        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
    }

    func testStartFailedInteract() throws {
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow.redirectUri, redirectUri)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNil(flow.context)
        
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-error-response"),
                          statusCode: 400)
        
        let wait = expectation(description: "start")
        flow.start { result in
            defer { wait.fulfill() }
            
            guard case let Result.failure(error) = result,
                  case let IDXAuthenticationFlowError.apiError(apiError) = error,
                  case let APIClientError.serverError(oauthError) = apiError,
                  let oauthError = oauthError as? OAuth2ServerError
            else {
                XCTFail("Received a success when a failure was expected")
                return
            }
            
            XCTAssertEqual(oauthError.code, "invalid_request")
            XCTAssertEqual(oauthError.description,
                           "PKCE code challenge is required when the token endpoint authentication method is \'NONE\'.")
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(flow.isAuthenticating)

        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }

    func testRedirectResultWithoutContext() throws {
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:///uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))

        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .invalidContext)
    }

    func testRedirectResultAuthenticated() throws {
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:///uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .authenticated)
    }

    func testRedirectResultWithInvalidUrl() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect///uri"))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .invalidRedirectUrl)
    }

    func testRedirectResultWithInvalidScheme() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect.com:///uri"))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .invalidRedirectUrl)
    }

    func testRedirectResultWithInvalidState() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state1"))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .invalidContext)
    }

    func testRedirectResultWithRemediationError() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state&error=interaction_required"))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .remediationRequired)
    }

    func testRedirectResultWithEmptyResponse() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state"))

        flow.context = context
        XCTAssertEqual(flow.redirectResult(for: redirectUrl), .invalidContext)
    }
}
