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

final class DirectAuth2FATests: XCTestCase {
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
    
#if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testUserPasswordAndOOB() async throws {
        // Ensure the initial state
        XCTAssertFalse(flow.isAuthenticating)
        
        // Begin
        let state = try await flow.start("jane.doe@example.com",
                                         with: .password("SuperSecret"))
        
        XCTAssertTrue(flow.isAuthenticating)
        switch state {
        case .success(_):
            XCTFail("Not expecting a successful token response")
        case .mfaRequired(let context):
            XCTAssertFalse(context.mfaToken.isEmpty)
            let newState = try await flow.resume(state, with: .oob(channel: .push))
            switch newState {
            case .success(_):
                // Success!
                break
            case .mfaRequired(_):
                XCTFail("Not expecting MFA Required")
            case .bindingUpdate(_):
                XCTFail("Not expecting binding update")
            case .webAuthn(request: _):
                XCTFail("Not expecting webauthn request")
            }
        case .bindingUpdate(_):
            XCTFail("Not expecting binding update")
        case .webAuthn(request: _):
            XCTFail("Not expecting webauthn request")
        }
        XCTAssertFalse(flow.isAuthenticating)
    }
#endif
}
