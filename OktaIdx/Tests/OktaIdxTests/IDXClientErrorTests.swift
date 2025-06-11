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

class IDXClientErrorTests: XCTestCase {
    func testEquality() {
        XCTAssertEqual(InteractionCodeFlowError.invalidFlow,
                       InteractionCodeFlowError.invalidFlow)

        XCTAssertEqual(InteractionCodeFlowError.authenticationIncomplete,
                       InteractionCodeFlowError.authenticationIncomplete)

        XCTAssertEqual(InteractionCodeFlowError.invalidParameter(name: "name"),
                       InteractionCodeFlowError.invalidParameter(name: "name"))
        XCTAssertNotEqual(InteractionCodeFlowError.invalidParameter(name: "first"),
                          InteractionCodeFlowError.invalidParameter(name: "last"))

        XCTAssertEqual(InteractionCodeFlowError.missingRequiredParameter(name: "name"),
                       InteractionCodeFlowError.missingRequiredParameter(name: "name"))
        XCTAssertNotEqual(InteractionCodeFlowError.missingRequiredParameter(name: "first"),
                          InteractionCodeFlowError.missingRequiredParameter(name: "last"))

        XCTAssertEqual(InteractionCodeFlowError.missingRemediation(name: "name"),
                       InteractionCodeFlowError.missingRemediation(name: "name"))
        XCTAssertNotEqual(InteractionCodeFlowError.missingRemediation(name: "first"),
                          InteractionCodeFlowError.missingRemediation(name: "last"))

        XCTAssertEqual(InteractionCodeFlowError.responseValidationFailed("message"),
                       InteractionCodeFlowError.responseValidationFailed("message"))
        XCTAssertNotEqual(InteractionCodeFlowError.responseValidationFailed("first"),
                          InteractionCodeFlowError.responseValidationFailed("last"))
        XCTAssertEqual(InteractionCodeFlowError.responseValidationFailed("message"),
                       InteractionCodeFlowError.responseValidationFailed("message"))
    }
    
    func testDescription() {
        XCTAssertEqual(InteractionCodeFlowError.invalidFlow.localizedDescription,
                       "InteractionCodeFlow instance is invalid.")
        XCTAssertEqual(InteractionCodeFlowError.authenticationIncomplete.localizedDescription,
                       "Cannot complete sign in since authentication is incomplete.")
        XCTAssertEqual(InteractionCodeFlowError.invalidParameter(name: "identifier").localizedDescription,
                       "Invalid parameter \"identifier\" supplied to a remediation option.")
        XCTAssertEqual(InteractionCodeFlowError.missingRequiredParameter(name: "passcode").localizedDescription,
                       "Required parameter \"passcode\" missing.")
        XCTAssertEqual(InteractionCodeFlowError.missingRemediation(name: "cancel").localizedDescription,
                       "Remediation option \"cancel\" missing.")
        XCTAssertEqual(InteractionCodeFlowError.responseValidationFailed("Some authenticators have differing types").localizedDescription,
                       "Response validation failed: Some authenticators have differing types.")
        XCTAssertEqual(InteractionCodeFlowError.responseValidationFailed("Invalid JSON value").localizedDescription,
                       "Response validation failed: Invalid JSON value.")
    }
}
