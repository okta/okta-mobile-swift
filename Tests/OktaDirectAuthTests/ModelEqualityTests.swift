//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

final class ModelEqualityTests: XCTestCase {
    typealias Status = DirectAuthenticationFlow.Status
    typealias MFAContext = DirectAuthenticationFlow.MFAContext
    typealias ContinuationType = DirectAuthenticationFlow.ContinuationType

    func testOOBChannelEquality() {
        XCTAssertEqual(DirectAuthenticationFlow.OOBChannel.sms, DirectAuthenticationFlow.OOBChannel.sms)
        XCTAssertNotEqual(DirectAuthenticationFlow.OOBChannel.sms, DirectAuthenticationFlow.OOBChannel.push)
    }
    
    func testMFAContextEquality() {
        XCTAssertEqual(MFAContext(supportedChallengeTypes: nil, mfaToken: "abcd123"),
                       MFAContext(supportedChallengeTypes: nil, mfaToken: "abcd123"))
        XCTAssertEqual(MFAContext(supportedChallengeTypes: .directAuth, mfaToken: "abcd123"),
                       MFAContext(supportedChallengeTypes: .directAuth, mfaToken: "abcd123"))
        XCTAssertNotEqual(MFAContext(supportedChallengeTypes: .directAuth, mfaToken: "abcd123"),
                          MFAContext(supportedChallengeTypes: [.password], mfaToken: "zyxw987"))
    }
    
    func testContinuationTypeEquality() {
        let oobResponse = OOBResponse(oobCode: "abcd123", expiresIn: 30, interval: 1, channel: .push, bindingMethod: .transfer, bindingCode: "1234")
        XCTAssertEqual(ContinuationType.prompt(.init(oobResponse: oobResponse, mfaContext: nil)),
                       ContinuationType.prompt(.init(oobResponse: oobResponse, mfaContext: nil)))
        XCTAssertNotEqual(
            ContinuationType.prompt(.init(oobResponse: oobResponse, mfaContext: nil)),
            ContinuationType.prompt(.init(oobResponse: oobResponse, mfaContext: .init(MFAContext(supportedChallengeTypes: .directAuth, mfaToken: "abcd123")))))
    }
    
    func testStatusEquality() {
        let oobResponse = OOBResponse(oobCode: "abcd123", expiresIn: 30, interval: 1, channel: .push, bindingMethod: .transfer, bindingCode: "1234")
        let mfaContext = MFAContext(supportedChallengeTypes: .directAuth, mfaToken: "abcd123")
        XCTAssertEqual(Status.success(.simpleMockToken),
                       Status.success(.simpleMockToken))
        XCTAssertEqual(Status.continuation(.prompt(.init(oobResponse: oobResponse, mfaContext: nil))),
                       Status.continuation(.prompt(.init(oobResponse: oobResponse, mfaContext: nil))))
        XCTAssertEqual(Status.continuation(.prompt(.init(oobResponse: oobResponse, mfaContext: mfaContext))),
                       Status.continuation(.prompt(.init(oobResponse: oobResponse, mfaContext: mfaContext))))
        XCTAssertEqual(Status.mfaRequired(mfaContext), Status.mfaRequired(mfaContext))
    }
}
