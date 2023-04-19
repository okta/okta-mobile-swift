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
@testable import OktaDirectAuth

final class ExtensionTests: XCTestCase {
    typealias Status = DirectAuthenticationFlow.Status
    typealias MFAContext = DirectAuthenticationFlow.MFAContext

    func testArrayExtensions() throws {
        XCTAssertEqual([GrantType].directAuth, [.password, .oob, .otp, .oobMFA, .otpMFA])
    }
    
    func testAuthFlowStatus() throws {
        XCTAssertNil(Status.success(Token.mockToken()).mfaToken)
        XCTAssertEqual(Status.mfaRequired(.init(supportedChallengeTypes: nil, mfaToken: "abc123")).mfaToken, "abc123")
    }
    
    func testStatusEquality() throws {
        let token = Token.mockToken()
        XCTAssertEqual(Status.success(token), .success(token))
        
        let context = MFAContext(supportedChallengeTypes: nil, mfaToken: "abc123")
        XCTAssertEqual(Status.mfaRequired(context), .mfaRequired(context))
        
        XCTAssertNotEqual(Status.success(token), .mfaRequired(context))
    }
}
