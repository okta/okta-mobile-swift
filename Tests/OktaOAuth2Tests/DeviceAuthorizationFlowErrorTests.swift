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

final class DeviceAuthorizationFlowErrorTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var flow: DeviceAuthorizationFlow!

    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        DeviceAuthorizationFlow.slowDownInterval = 0.25
        flow = client.deviceAuthorizationFlow()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
        DeviceAuthorizationFlow.resetToDefault()
    }

    private enum MockRequestExpectations {
        case slowDown, authorizationPending
    }

    private func prepareRequests(mock type: MockRequestExpectations) throws {
        switch type {
        case .slowDown:
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/device/authorize",
                              data: try data(from: .module, for: "device-authorize", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token-slow_down", in: "MockResponses"),
                              statusCode: 400,
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                              data: try data(from: .module, for: "keys", in: "MockResponses"),
                              contentType: "application/json")

        case .authorizationPending:
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/device/authorize",
                              data: try data(from: .module, for: "device-authorize", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token-authorization_pending", in: "MockResponses"),
                              statusCode: 400,
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                              data: try data(from: .module, for: "keys", in: "MockResponses"),
                              contentType: "application/json")
        }
    }

    func testSlowDown() async throws {
        try prepareRequests(mock: .slowDown)
        try await performAuthenticationFlow(isAsync: false)
    }

    func testAuthorizationPending() async throws {
        try prepareRequests(mock: .authorizationPending)
        try await performAuthenticationFlow(isAsync: false)
    }

    func testSlowDownAsync() async throws {
        try prepareRequests(mock: .slowDown)
        try await performAuthenticationFlow(isAsync: true)
    }

    func testAuthorizationPendingAsync() async throws {
        try prepareRequests(mock: .authorizationPending)
        try await performAuthenticationFlow(isAsync: true)
    }

    func performAuthenticationFlow(isAsync: Bool) async throws {
        // Ensure the initial state
        await XCTAssertNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.isAuthenticating)

        // Begin
        nonisolated(unsafe) var verification: DeviceAuthorizationFlow.Verification?
        if isAsync {
            verification = try await flow.start()
        } else {
            let startWait = expectation(description: "start")
            flow.start { result in
                switch result {
                case .success(let response):
                    verification = response
                case .failure(let error):
                    XCTAssertNil(error)
                }
                startWait.fulfill()
            }
            await fulfillment(of: [startWait], timeout: 2)
        }

        verification = try XCTUnwrap(verification)
        try await XCTAssertEqualAsync(await flow.context?.verification?.deviceCode, verification?.deviceCode)
        await XCTAssertTrueAsync(await flow.isAuthenticating)
        await XCTAssertNotNilAsync(await flow.context?.verification?.verificationUri)
        try await XCTAssertEqualAsync(verification, await flow.context?.verification)
        try await XCTAssertEqualAsync(await flow.context?.verification?.verificationUri.absoluteString, "https://example.okta.com/activate")
        try await XCTAssertEqualAsync(await flow.context?.verification?.interval, 1)

        // Exchange code
        nonisolated(unsafe) var token: Token?
        if isAsync {
            token = try await flow.resume()
        } else {
            let resumeWait = expectation(description: "resume")
            flow.resume { result in
                switch result {
                case .success(let resultToken):
                    token = resultToken
                case .failure(let error):
                    XCTAssertNil(error)
                }
                resumeWait.fulfill()
            }
            await fulfillment(of: [resumeWait], timeout: 2)
        }

        await XCTAssertNotNilAsync(await flow.context)
        await XCTAssertFalseAsync(await flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
}
