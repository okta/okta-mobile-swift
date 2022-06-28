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
        XCTAssertEqual(IDXAuthenticationFlowError.invalidFlow,
                       IDXAuthenticationFlowError.invalidFlow)
        XCTAssertEqual(IDXAuthenticationFlowError.cannotCreateRequest,
                       IDXAuthenticationFlowError.cannotCreateRequest)
        XCTAssertEqual(IDXAuthenticationFlowError.invalidHTTPResponse,
                       IDXAuthenticationFlowError.invalidHTTPResponse)
        XCTAssertEqual(IDXAuthenticationFlowError.invalidResponseData,
                       IDXAuthenticationFlowError.invalidResponseData)
        XCTAssertEqual(IDXAuthenticationFlowError.invalidRequestData,
                       IDXAuthenticationFlowError.invalidRequestData)
        XCTAssertEqual(IDXAuthenticationFlowError.successResponseMissing,
                       IDXAuthenticationFlowError.successResponseMissing)
        XCTAssertEqual(IDXAuthenticationFlowError.serverError(message: "Message", localizationKey: "key", type: "type"),
                       IDXAuthenticationFlowError.serverError(message: "Message", localizationKey: "key", type: "type"))
        XCTAssertEqual(IDXAuthenticationFlowError.invalidParameter(name: "name"),
                       IDXAuthenticationFlowError.invalidParameter(name: "name"))
        XCTAssertEqual(IDXAuthenticationFlowError.invalidParameterValue(name: "name", type: "type"),
                       IDXAuthenticationFlowError.invalidParameterValue(name: "name", type: "type"))
        XCTAssertEqual(IDXAuthenticationFlowError.parameterImmutable(name: "name"),
                       IDXAuthenticationFlowError.parameterImmutable(name: "name"))
        XCTAssertEqual(IDXAuthenticationFlowError.missingRequiredParameter(name: "name"),
                       IDXAuthenticationFlowError.missingRequiredParameter(name: "name"))
        XCTAssertEqual(IDXAuthenticationFlowError.unknownRemediationOption(name: "name"),
                       IDXAuthenticationFlowError.unknownRemediationOption(name: "name"))
        
        XCTAssertNotEqual(IDXAuthenticationFlowError.serverError(message: "Message", localizationKey: "key", type: "type"),
                          IDXAuthenticationFlowError.serverError(message: "Other", localizationKey: "other", type: "type"))
        XCTAssertNotEqual(IDXAuthenticationFlowError.invalidParameter(name: "name1"),
                          IDXAuthenticationFlowError.invalidParameter(name: "name2"))
        XCTAssertNotEqual(IDXAuthenticationFlowError.invalidParameterValue(name: "name1", type: "type"),
                          IDXAuthenticationFlowError.invalidParameterValue(name: "name2", type: "type"))
        XCTAssertNotEqual(IDXAuthenticationFlowError.parameterImmutable(name: "name1"),
                          IDXAuthenticationFlowError.parameterImmutable(name: "name2"))
        XCTAssertNotEqual(IDXAuthenticationFlowError.missingRequiredParameter(name: "name1"),
                          IDXAuthenticationFlowError.missingRequiredParameter(name: "name2"))
        XCTAssertNotEqual(IDXAuthenticationFlowError.unknownRemediationOption(name: "option1"),
                          IDXAuthenticationFlowError.unknownRemediationOption(name: "option2"))
        
        XCTAssertNotEqual(IDXAuthenticationFlowError.invalidFlow,
                          IDXAuthenticationFlowError.invalidHTTPResponse)
    }
    
    func testDescription() {
        XCTAssertEqual(IDXAuthenticationFlowError.invalidFlow.localizedDescription,
                       "IDXAuthenticationFlow instance is invalid.")
        XCTAssertEqual(IDXAuthenticationFlowError.cannotCreateRequest.localizedDescription,
                       "Could not create a URL request for this action.")
        XCTAssertEqual(IDXAuthenticationFlowError.invalidHTTPResponse.localizedDescription,
                       "Response received from a URL request is invalid.")
        XCTAssertEqual(IDXAuthenticationFlowError.invalidResponseData.localizedDescription,
                       "Response data is invalid or could not be parsed.")
        XCTAssertEqual(IDXAuthenticationFlowError.invalidRequestData.localizedDescription,
                       "Request data is invalid or could not be parsed.")
        XCTAssertEqual(IDXAuthenticationFlowError.serverError(message: "Message", localizationKey: "key", type: "type").localizedDescription,
                       "Message")
        XCTAssertEqual(IDXAuthenticationFlowError.invalidParameter(name: "name").localizedDescription,
                       "Invalid parameter \"name\" supplied to a remediation option.")
        XCTAssertEqual(IDXAuthenticationFlowError.internalMessage("name").localizedDescription,
                       "name")
        XCTAssertEqual(IDXAuthenticationFlowError.invalidParameterValue(name: "name", type: "string").localizedDescription,
                       "Parameter \"name\" was supplied a string value which is unsupported.")
        XCTAssertEqual(IDXAuthenticationFlowError.parameterImmutable(name: "name").localizedDescription,
                       "Cannot override immutable remediation parameter \"name\".")
        XCTAssertEqual(IDXAuthenticationFlowError.missingRequiredParameter(name: "name").localizedDescription,
                       "Required parameter \"name\" missing.")
        XCTAssertEqual(IDXAuthenticationFlowError.unknownRemediationOption(name: "name").localizedDescription,
                       "Unknown remediation option \"name\".")
        XCTAssertEqual(IDXAuthenticationFlowError.successResponseMissing.localizedDescription,
                       "Success response is missing or unavailable.")
    }
}
