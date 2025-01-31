//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaDirectAuth

final class DirectAuth1FATests: XCTestCase {
    let issuer = URL(string: "https://example.com/oauth2/default")!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    var flow: DirectAuthenticationFlow!

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "theClientId",
                              scope: "openid profile offline_access",
                              session: urlSession)
        flow = client.directAuthenticationFlow()

        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        throw XCTSkip("Skipping integration tests")
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testUserAndPassword() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        
        // Begin
        let state = try await flow.start("jane.doe@example.com",
                                         with: .password("SuperSecret"))
        
        XCTAssertFalse(flow.isAuthenticating)
        switch state {
        case .success(let token):
            XCTAssertNotNil(token.refreshToken)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        case .continuation(_):
            XCTFail("Not expecting continuation status")
        }
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testUserAndOTP() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        
        // Begin
        let state = try await flow.start("jane.doe@example.com",
                                         with: .otp(code: "123456"))
        
        XCTAssertFalse(flow.isAuthenticating)
        switch state {
        case .success(let token):
            XCTAssertNotNil(token.refreshToken)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        case .continuation(_):
            XCTFail("Not expecting continuation status")
        }
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testUserAndOOBPush() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        
        // Begin
        let state = try await flow.start("jane.doe@example.com",
                                         with: .oob(channel: .push))
        
        XCTAssertFalse(flow.isAuthenticating)
        switch state {
        case .success(let token):
            XCTAssertNotNil(token.refreshToken)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        case .continuation(_):
            XCTFail("Not expecting continuation status")
        }
    }
}
