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

class InteractionCodeFlowTests: XCTestCase {
    var issuer: URL!
    var client: OAuth2Client!
    var urlSession: URLSessionMock!
    var redirectUri: URL!
    var flow: InteractionCodeFlow!
    var delegate: DelegateRecorder!

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              session: urlSession)
        flow = try InteractionCodeFlow(client: client)

        delegate = DelegateRecorder()
        flow.add(delegate: delegate)

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module,
                                         for: "openid-configuration"))
    }
    
    func testStartSuccess() async throws {
        XCTAssertNotNil(flow)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNil(flow.context)
        
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        
        let response = try await flow.start()
        XCTAssertNotNil(response.remediations[.identify])
        XCTAssertTrue(flow.isAuthenticating)

        let context = try XCTUnwrap(flow.context)
        XCTAssertNotNil(context.state)
        XCTAssertEqual(context.interactionHandle, "003Q14X7li")

        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
    }
    
    func testStartWithOptions() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        
        let response = try await flow.start(with: .init(state: "CustomState"))
        XCTAssertNotNil(response.remediations[.identify])
        XCTAssertEqual(flow.context?.state, "CustomState")
    }

    func testStartFailedInteract() async throws {
        XCTAssertNotNil(flow)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNil(flow.context)
        
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-error-response"),
                          statusCode: 400)

        let error = await XCTAssertThrowsErrorAsync(try await flow.start())
        let apiError = try XCTUnwrap(error as? APIClientError)
        guard case let .httpError(httpError) = apiError
        else {
            XCTFail("Received an unexpected error type: \(String(describing: error))")
            return
        }

        let oauthError = try XCTUnwrap(httpError as? OAuth2ServerError)
        XCTAssertEqual(oauthError.code, .invalidRequest)
        XCTAssertEqual(oauthError.description,
                       "PKCE code challenge is required when the token endpoint authentication method is \'NONE\'.")
        XCTAssertFalse(flow.isAuthenticating)

        await MainActor.yield()
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }

    func testRedirectResultWithoutContext() async throws {
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:///uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))

        let error = await XCTAssertThrowsErrorAsync(try await flow.resume(with: redirectUrl))
        let oauth2Error = try XCTUnwrap(error as? OAuth2Error)
        XCTAssertEqual(oauth2Error, .invalidContext)
    }

    func testRedirectResultAuthenticated() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        urlSession.expect("https://example.com/oauth2/default/v1/token",
                          data: try data(from: .module,
                                         for: "token-response"))
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:/uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))

        _ = try await flow.start(with: .init(state: "state"))
        let redirectResult = try await flow.resume(with: redirectUrl)
        switch redirectResult {
        case .success(let token):
            XCTAssertEqual(token.refreshToken, "CCY4M4fR3")
        case .interactionRequired(_):
            XCTFail("Should have received a token")
        }
    }

    func testRedirectResultWithInvalidUrl() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        let redirectUrl = try XCTUnwrap(URL(string: "redirect///uri"))

        _ = try await flow.start(with: .init(state: "state"))
        do {
            _ = try await flow.resume(with: redirectUrl)
            XCTFail("Should have received an error")
        } catch let error as OAuth2Error {
            XCTAssertEqual(error, .redirectUri(redirectUrl, reason: .scheme(nil)))
        } catch {
            XCTFail("Received an unexpected error result \(error)")
        }
    }

    func testRedirectResultWithInvalidScheme() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        let redirectUrl = try XCTUnwrap(URL(string: "redirect.com:///uri"))

        _ = try await flow.start(with: .init(state: "state"))
        do {
            _ = try await flow.resume(with: redirectUrl)
            XCTFail("Should have received an error")
        } catch let error as OAuth2Error {
            XCTAssertEqual(error, .redirectUri(redirectUrl, reason: .scheme("redirect.com")))
        } catch {
            XCTFail("Received an unexpected error result \(error)")
        }
    }

    func testRedirectResultWithInvalidState() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:/uri?state=state1"))

        _ = try await flow.start(with: .init(state: "state"))
        do {
            _ = try await flow.resume(with: redirectUrl)
            XCTFail("Should have received an error")
        } catch let error as OAuth2Error {
            XCTAssertEqual(error, .redirectUri(redirectUrl, reason: .state("state1")))
        } catch {
            XCTFail("Received an unexpected error result \(error)")
        }
    }

    func testRedirectResultWithRemediationRequired() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "interact-response"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))

        _ = try await flow.start(with: .init(state: "state"))

        let redirectUrl = try XCTUnwrap(URL(string: "redirect:/uri?state=state&error=interaction_required"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "introspect-response"))

        let redirectResult = try await flow.resume(with: redirectUrl)
        switch redirectResult {
        case .success(_):
            XCTFail("Should have received a interaction response")
        case .interactionRequired(let response):
            XCTAssertNotNil(response)
        }
    }
}
