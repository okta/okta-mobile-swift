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
        client = OAuth2Client(baseURL: issuer,
                              clientId: "theClientId",
                              scopes: "openid profile offline_access",
                              session: urlSession)
        flow = client.directAuthenticationFlow(additionalParameters: [:])

        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
#if swift(>=5.5.1)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
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
        case .failure(let error):
            XCTFail(error.localizedDescription)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
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
        case .failure(let error):
            XCTFail(error.localizedDescription)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
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
        case .failure(let error):
            XCTFail(error.localizedDescription)
        case .mfaRequired(_):
            XCTFail("Not expecting MFA Required")
        }
    }
#endif
}
