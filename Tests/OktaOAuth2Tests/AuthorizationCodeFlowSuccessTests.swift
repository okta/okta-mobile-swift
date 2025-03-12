//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class AuthorizationCodeFlowDelegateRecorder: AuthorizationCodeFlowDelegate {
    var token: Token?
    var error: OAuth2Error?
    var url: URL?
    var started = false
    var finished = false
    
    func authenticationStarted<Flow: AuthorizationCodeFlow>(flow: Flow) {
        started = true
    }
    
    func authenticationFinished<Flow: AuthorizationCodeFlow>(flow: Flow) {
        finished = true
    }

    func authentication<Flow>(flow: Flow, received token: Token) {
        self.token = token
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }

    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents) {
        urlComponents.fragment = "customizedUrl"
    }
    
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, shouldAuthenticateUsing url: URL) {
        self.url = url
    }
}

final class AuthorizationCodeFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com/oauth2/default")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: AuthorizationCodeFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")

        flow = try client.authorizationCodeFlow(additionalParameters: ["additional": "param"])
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testWithDelegate() async throws {
        let delegate = AuthorizationCodeFlowDelegateRecorder()
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)

        // Begin
        let context = AuthorizationCodeFlow.Context(pkce: nil,
                                                    nonce: "nonce_string",
                                                    maxAge: nil,
                                                    acrValues: nil,
                                                    state: "ABC123",
                                                    additionalParameters: ["foo": "bar"])
        let url = try await flow.start(with: context)
        await MainActor.yield()

        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(url, flow.context?.authenticationURL)
        XCTAssertEqual(url.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123#customizedUrl")
        XCTAssertTrue(delegate.started)
        XCTAssertEqual(flow.context?.authenticationURL, delegate.url)

        // Exchange code
        let token = try await flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!)
        await MainActor.yield()

        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertEqual(token, delegate.token)
        XCTAssertTrue(delegate.finished)
    }

    func testWithBlocks() async throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        let context = AuthorizationCodeFlow.Context(pkce: nil,
                                                    nonce: "nonce_string",
                                                    maxAge: nil,
                                                    acrValues: ["some:acr:value"],
                                                    state: "ABC123",
                                                    additionalParameters: ["foo": "bar"])
        let startWait = expectation(description: "resume")
        nonisolated(unsafe) var url: URL?
        flow.start(with: context) { result in
            switch result {
            case .success(let redirectUrl):
                url = redirectUrl
            case .failure(let error):
                XCTAssertNil(error)
            }
            startWait.fulfill()
        }
        await fulfillment(of: [startWait], timeout: 1)

        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(url, flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?acr_values=some:acr:value&additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123")

        // Exchange code
        nonisolated(unsafe) var token: Token?
        let resumeWait = expectation(description: "resume")
        try flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!) { result in
            switch result {
            case .success(let resultToken):
                token = resultToken
            case .failure(let error):
                XCTAssertNil(error)
            }
            resumeWait.fulfill()
        }
        await fulfillment(of: [resumeWait], timeout: 1)

        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
        
        XCTAssertEqual(token?.context.clientSettings, [
            "acr_values": "some:acr:value",
        ])
        
        XCTAssertEqual(try XCTUnwrap(urlSession.formDecodedBody(matching: "/v1/token")), [
            "grant_type": "authorization_code",
            "redirect_uri": "com.example:/callback",
            "scope": "openid+profile",
            "client_id": "clientId",
            "code": "ABCEasyAs123",
            "additional": "param",
            "foo": "bar",
        ])
    }

    func testWithAsync() async throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        let context = AuthorizationCodeFlow.Context(pkce: nil,
                                                    nonce: "nonce_string",
                                                    maxAge: nil,
                                                    acrValues: nil,
                                                    state: "ABC123",
                                                    additionalParameters: ["foo": "bar"])
        let url = try await flow.start(with: context)
        
        XCTAssertEqual(flow.context?.state, context.state)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.authenticationURL)
        XCTAssertEqual(url, flow.context?.authenticationURL)
        XCTAssertEqual(flow.context?.authenticationURL?.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize?additional=param&client_id=clientId&foo=bar&nonce=nonce_string&redirect_uri=com.example:/callback&response_type=code&scope=openid%20profile&state=ABC123")

        // Exchange code
        let token = try await flow.resume(with: URL(string: "com.example:/callback?code=ABCEasyAs123&state=ABC123")!)

        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
    
    func testAuthorizationCodeFromURL() async throws {
        typealias RedirectError = AuthorizationCodeFlow.RedirectError

        XCTAssertThrowsError(try URL(string: "https://example.com")!.authorizationCode(redirectUri: redirectUri, state: "ABC123" )) { error in
            XCTAssertEqual(error as? RedirectError, .unexpectedScheme("https"))
        }

        XCTAssertEqual(try URL(string: "com.example:/?state=ABC123&code=foo")!.authorizationCode(redirectUri: redirectUri, state: "ABC123"), "foo")
    }
    
    func testTokenRequestParameters() throws {
        let (openIdConfiguration, _) = try openIdConfiguration()
        let pkce = try XCTUnwrap(PKCE())
        
        var request: AuthorizationCodeFlow.TokenRequest
        
        // No authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                        clientConfiguration: .init(issuerURL: issuer,
                                                   clientId: "theClientId",
                                                   scope: "openid profile",
                                                   redirectUri: URL(string: "https://example.com/redirect")!),
                        additionalParameters: nil,
                        context: .init(pkce: pkce,
                                       nonce: "nonce_str",
                                       maxAge: 60,
                                       acrValues: nil,
                                       state: "the_state",
                                       additionalParameters: nil),
                        authorizationCode: "abcd123")
        XCTAssertEqual(request.bodyParameters?.stringComponents,
                       [
                        "client_id": "theClientId",
                        "redirect_uri": "https://example.com/redirect",
                        "scope": "openid profile",
                        "grant_type": "authorization_code",
                        "code_verifier": pkce.codeVerifier,
                        "code": "abcd123"
                       ])

        // Client Secret authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                            clientConfiguration: .init(issuerURL: issuer,
                                                       clientId: "theClientId",
                                                       scope: "openid profile",
                                                       redirectUri: URL(string: "https://example.com/redirect")!,
                                                       authentication: .clientSecret("supersecret")),
                            additionalParameters: nil,
                            context: .init(pkce: pkce,
                                           nonce: "nonce_str",
                                           maxAge: 60,
                                           acrValues: nil,
                                           state: "the_state",
                                           additionalParameters: nil),
                            authorizationCode: "abcd123")
        XCTAssertEqual(request.bodyParameters?.stringComponents,
                       [
                        "client_id": "theClientId",
                        "client_secret": "supersecret",
                        "redirect_uri": "https://example.com/redirect",
                        "scope": "openid profile",
                        "grant_type": "authorization_code",
                        "code_verifier": pkce.codeVerifier,
                        "code": "abcd123"
                       ])
    }
}
