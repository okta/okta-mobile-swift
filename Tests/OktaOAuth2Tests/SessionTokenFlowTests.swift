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

#if canImport(UIKit) || canImport(AppKit)
import XCTest
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

class MockSessionTokenFlowURLExchange: SessionTokenFlowURLExchange {
    let scheme: String
    static let resultUrl = LockedValue<URL?>(wrappedValue: nil)
    static let error: LockedValue<OAuth2Error?> = nil
    static func reset() {
        resultUrl.wrappedValue = nil
        error.wrappedValue = nil
    }

    required init(scheme: String) {
        self.scheme = scheme
    }

    func follow(url: URL) async throws -> URL {
        if let resultUrl = type(of: self).resultUrl.wrappedValue {
            return resultUrl
        } else if let error = type(of: self).error.wrappedValue {
            throw error
        }
        throw OAuth2Error.invalidUrl
    }
}

final class SessionTokenFlowSuccessTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: SessionTokenFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        SessionTokenFlow.urlExchangeClass = MockSessionTokenFlowURLExchange.self

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        flow = try client.sessionTokenFlow(additionalParameters: ["additional": "param"])
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
        SessionTokenFlow.reset()
        MockSessionTokenFlowURLExchange.reset()
    }

    func testWithDelegate() async throws {
        let delegate = AuthenticationDelegateRecorder()
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)

        MockSessionTokenFlowURLExchange.resultUrl.wrappedValue = URL(string: "com.example:/callback?code=abc123&state=state")

        // Authenticate
        let token = try await flow.start(with: "theSessionToken", context: .init(state: "state"))
        await MainActor.yield()

        XCTAssertTrue(delegate.started)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertEqual(token, delegate.token)
        XCTAssertTrue(delegate.finished)
    }

    func testWithAsync() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)

        MockSessionTokenFlowURLExchange.resultUrl.wrappedValue = URL(string: "com.example:/callback?code=abc123&state=state")

        // Authenticate
        let token = try await flow.start(with: "theSessionToken", context: .init(state: "state"))

        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
}
#endif
