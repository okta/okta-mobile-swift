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
        XCTAssertEqual(InteractionCodeFlowError.cannotCreateRequest,
                       InteractionCodeFlowError.cannotCreateRequest)
        XCTAssertEqual(InteractionCodeFlowError.invalidHTTPResponse,
                       InteractionCodeFlowError.invalidHTTPResponse)
        XCTAssertEqual(InteractionCodeFlowError.invalidResponseData,
                       InteractionCodeFlowError.invalidResponseData)
        XCTAssertEqual(InteractionCodeFlowError.invalidRequestData,
                       InteractionCodeFlowError.invalidRequestData)
        XCTAssertEqual(InteractionCodeFlowError.successResponseMissing,
                       InteractionCodeFlowError.successResponseMissing)
        XCTAssertEqual(InteractionCodeFlowError.serverError(message: "Message", localizationKey: "key", type: "type"),
                       InteractionCodeFlowError.serverError(message: "Message", localizationKey: "key", type: "type"))
        XCTAssertEqual(InteractionCodeFlowError.invalidParameter(name: "name"),
                       InteractionCodeFlowError.invalidParameter(name: "name"))
        XCTAssertEqual(InteractionCodeFlowError.invalidParameterValue(name: "name", type: "type"),
                       InteractionCodeFlowError.invalidParameterValue(name: "name", type: "type"))
        XCTAssertEqual(InteractionCodeFlowError.parameterImmutable(name: "name"),
                       InteractionCodeFlowError.parameterImmutable(name: "name"))
        XCTAssertEqual(InteractionCodeFlowError.missingRequiredParameter(name: "name"),
                       InteractionCodeFlowError.missingRequiredParameter(name: "name"))
        XCTAssertEqual(InteractionCodeFlowError.unknownRemediationOption(name: "name"),
                       InteractionCodeFlowError.unknownRemediationOption(name: "name"))
        
        XCTAssertNotEqual(InteractionCodeFlowError.serverError(message: "Message", localizationKey: "key", type: "type"),
                          InteractionCodeFlowError.serverError(message: "Other", localizationKey: "other", type: "type"))
        XCTAssertNotEqual(InteractionCodeFlowError.invalidParameter(name: "name1"),
                          InteractionCodeFlowError.invalidParameter(name: "name2"))
        XCTAssertNotEqual(InteractionCodeFlowError.invalidParameterValue(name: "name1", type: "type"),
                          InteractionCodeFlowError.invalidParameterValue(name: "name2", type: "type"))
        XCTAssertNotEqual(InteractionCodeFlowError.parameterImmutable(name: "name1"),
                          InteractionCodeFlowError.parameterImmutable(name: "name2"))
        XCTAssertNotEqual(InteractionCodeFlowError.missingRequiredParameter(name: "name1"),
                          InteractionCodeFlowError.missingRequiredParameter(name: "name2"))
        XCTAssertNotEqual(InteractionCodeFlowError.unknownRemediationOption(name: "option1"),
                          InteractionCodeFlowError.unknownRemediationOption(name: "option2"))
        
        XCTAssertNotEqual(InteractionCodeFlowError.invalidFlow,
                          InteractionCodeFlowError.invalidHTTPResponse)
    }
    
    func testDescription() {
        XCTAssertEqual(InteractionCodeFlowError.invalidFlow.localizedDescription,
                       "InteractionCodeFlow instance is invalid.")
        XCTAssertEqual(InteractionCodeFlowError.cannotCreateRequest.localizedDescription,
                       "Could not create a URL request for this action.")
        XCTAssertEqual(InteractionCodeFlowError.invalidHTTPResponse.localizedDescription,
                       "Response received from a URL request is invalid.")
        XCTAssertEqual(InteractionCodeFlowError.invalidResponseData.localizedDescription,
                       "Response data is invalid or could not be parsed.")
        XCTAssertEqual(InteractionCodeFlowError.invalidRequestData.localizedDescription,
                       "Request data is invalid or could not be parsed.")
        XCTAssertEqual(InteractionCodeFlowError.serverError(message: "Message", localizationKey: "key", type: "type").localizedDescription,
                       "Message")
        XCTAssertEqual(InteractionCodeFlowError.invalidParameter(name: "name").localizedDescription,
                       "Invalid parameter \"name\" supplied to a remediation option.")
        XCTAssertEqual(InteractionCodeFlowError.internalMessage("name").localizedDescription,
                       "name")
        XCTAssertEqual(InteractionCodeFlowError.invalidParameterValue(name: "name", type: "string").localizedDescription,
                       "Parameter \"name\" was supplied a string value which is unsupported.")
        XCTAssertEqual(InteractionCodeFlowError.parameterImmutable(name: "name").localizedDescription,
                       "Cannot override immutable remediation parameter \"name\".")
        XCTAssertEqual(InteractionCodeFlowError.missingRequiredParameter(name: "name").localizedDescription,
                       "Required parameter \"name\" missing.")
        XCTAssertEqual(InteractionCodeFlowError.unknownRemediationOption(name: "name").localizedDescription,
                       "Unknown remediation option \"name\".")
        XCTAssertEqual(InteractionCodeFlowError.successResponseMissing.localizedDescription,
                       "Success response is missing or unavailable.")
    }
}
