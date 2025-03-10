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

final class DeviceAuthorizationFlowSuccessTests: XCTestCase {
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

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/device/authorize",
                          data: try data(from: .module, for: "device-authorize", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        flow = client.deviceAuthorizationFlow()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    func testWithDelegate() throws {
        let delegate = DeviceAuthorizationFlowDelegateRecorder()
        flow.add(delegate: delegate)

        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertFalse(delegate.started)
        
        // Begin
        var expect = expectation(description: "resume")
        flow.start() { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }

        XCTAssertNotNil(delegate.verification)
        XCTAssertEqual(flow.context?.verification, delegate.verification)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertEqual(delegate.verification?.verificationUri.absoluteString, "https://example.okta.com/activate")
        XCTAssertTrue(delegate.started)
        
        // Exchange code
        expect = expectation(description: "Wait for timer")
        flow.resume() { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(delegate.token)
        XCTAssertTrue(delegate.finished)
    }

    func testWithBlocks() throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        var wait = expectation(description: "resume")
        var verification: DeviceAuthorizationFlow.Verification?
        flow.start { result in
            switch result {
            case .success(let response):
                verification = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        
        verification = try XCTUnwrap(verification)
        XCTAssertEqual(flow.context?.verification?.deviceCode, verification?.deviceCode)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertNotNil(flow.context?.verification?.verificationUri)
        XCTAssertEqual(verification, flow.context?.verification)
        XCTAssertEqual(flow.context?.verification?.verificationUri.absoluteString, "https://example.okta.com/activate")

        // Exchange code
        var token: Token?
        wait = expectation(description: "resume")
        flow.resume { result in
            switch result {
            case .success(let resultToken):
                token = resultToken
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }

        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testWithAsync() async throws {
        // Ensure the initial state
        XCTAssertNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)

        // Begin
        let verification = try await flow.start()

        XCTAssertEqual(flow.context?.verification, verification)
        XCTAssertTrue(flow.isAuthenticating)
        XCTAssertEqual(verification, flow.context?.verification)
        XCTAssertEqual(flow.context?.verification?.verificationUri.absoluteString, "https://example.okta.com/activate")

        // Exchange code
        let token = try await flow.resume()

        XCTAssertNotNil(flow.context)
        XCTAssertFalse(flow.isAuthenticating)
        XCTAssertNotNil(token)
    }
    
    func testContextResponse() throws {
        let data = data(for: """
            {
                "device_code": "1a521d9f-0922-4e6d-8db9-8b654297435a",
                "user_code": "GDLMZQCT",
                "verification_uri": "https://example.okta.com/activate",
                "expires_in": 600
            }
        """)
        let context = try defaultJSONDecoder.decode(DeviceAuthorizationFlow.Verification.self, from: data)

        XCTAssertEqual(context.deviceCode, "1a521d9f-0922-4e6d-8db9-8b654297435a")
        XCTAssertEqual(context.userCode, "GDLMZQCT")
        XCTAssertEqual(context.verificationUri.absoluteString, "https://example.okta.com/activate")
        XCTAssertEqual(context.expiresIn, 600)
        XCTAssertEqual(context.interval, 5)
        XCTAssertNil(context.verificationUriComplete)
    }
}
