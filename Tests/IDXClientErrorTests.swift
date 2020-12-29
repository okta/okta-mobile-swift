//
//  IDXClientErrorTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-28.
//

import XCTest
@testable import OktaIdx

class IDXClientErrorTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(IDXClientError.invalidClient,          IDXClientError.invalidClient)
        XCTAssertEqual(IDXClientError.stateHandleMissing,     IDXClientError.stateHandleMissing)
        XCTAssertEqual(IDXClientError.cannotCreateRequest,    IDXClientError.cannotCreateRequest)
        XCTAssertEqual(IDXClientError.invalidHTTPResponse,    IDXClientError.invalidHTTPResponse)
        XCTAssertEqual(IDXClientError.invalidResponseData,    IDXClientError.invalidResponseData)
        XCTAssertEqual(IDXClientError.invalidRequestData,     IDXClientError.invalidRequestData)
        XCTAssertEqual(IDXClientError.successResponseMissing, IDXClientError.successResponseMissing)
        XCTAssertEqual(IDXClientError.serverError(message: "Message", localizationKey: "key", type: "type"),
                       IDXClientError.serverError(message: "Message", localizationKey: "key", type: "type"))
        XCTAssertEqual(IDXClientError.invalidParameter(name: "name"),
                       IDXClientError.invalidParameter(name: "name"))
        XCTAssertEqual(IDXClientError.invalidParameterValue(name: "name", type: "type"),
                       IDXClientError.invalidParameterValue(name: "name", type: "type"))
        XCTAssertEqual(IDXClientError.parameterImmutable(name: "name"),
                       IDXClientError.parameterImmutable(name: "name"))
        XCTAssertEqual(IDXClientError.missingRequiredParameter(name: "name"),
                       IDXClientError.missingRequiredParameter(name: "name"))
        XCTAssertEqual(IDXClientError.unknownRemediationOption(name: "name"),
                       IDXClientError.unknownRemediationOption(name: "name"))
        
        XCTAssertNotEqual(IDXClientError.serverError(message: "Message", localizationKey: "key", type: "type"),
                          IDXClientError.serverError(message: "Other", localizationKey: "other", type: "type"))
        XCTAssertNotEqual(IDXClientError.invalidParameter(name: "name1"),
                          IDXClientError.invalidParameter(name: "name2"))
        XCTAssertNotEqual(IDXClientError.invalidParameterValue(name: "name1", type: "type"),
                          IDXClientError.invalidParameterValue(name: "name2", type: "type"))
        XCTAssertNotEqual(IDXClientError.parameterImmutable(name: "name1"),
                          IDXClientError.parameterImmutable(name: "name2"))
        XCTAssertNotEqual(IDXClientError.missingRequiredParameter(name: "name1"),
                          IDXClientError.missingRequiredParameter(name: "name2"))
        XCTAssertNotEqual(IDXClientError.unknownRemediationOption(name: "option1"),
                          IDXClientError.unknownRemediationOption(name: "option2"))
        
        XCTAssertNotEqual(IDXClientError.invalidClient, IDXClientError.invalidHTTPResponse)
    }
    
    func testDescription() {
        XCTAssertEqual(IDXClientError.invalidClient.localizedDescription,
                       "IDXClient instance is invalid.")
        XCTAssertEqual(IDXClientError.stateHandleMissing.localizedDescription,
                       "State handle missing.")
        XCTAssertEqual(IDXClientError.cannotCreateRequest.localizedDescription,
                       "Could not create a URL request for this action.")
        XCTAssertEqual(IDXClientError.invalidHTTPResponse.localizedDescription,
                       "Response received from a URL request is invalid.")
        XCTAssertEqual(IDXClientError.invalidResponseData.localizedDescription,
                       "Response data is invalid or could not be parsed.")
        XCTAssertEqual(IDXClientError.invalidRequestData.localizedDescription,
                       "Request data is invalid or could not be parsed.")
        XCTAssertEqual(IDXClientError.serverError(message: "Message", localizationKey: "key", type: "type").localizedDescription,
                       "Message")
        XCTAssertEqual(IDXClientError.invalidParameter(name: "name").localizedDescription,
                       "Invalid parameter \"name\" supplied to a remediation option.")
        XCTAssertEqual(IDXClientError.invalidParameterValue(name: "name", type: "string").localizedDescription,
                       "Parameter \"name\" was supplied a string value which is unsupported.")
        XCTAssertEqual(IDXClientError.parameterImmutable(name: "name").localizedDescription,
                       "Cannot override immutable remediation parameter \"name\".")
        XCTAssertEqual(IDXClientError.missingRequiredParameter(name: "name").localizedDescription,
                       "Required parameter \"name\" missing.")
        XCTAssertEqual(IDXClientError.unknownRemediationOption(name: "name").localizedDescription,
                       "Unknown remediation option \"name\".")
        XCTAssertEqual(IDXClientError.successResponseMissing.localizedDescription,
                       "Success response is missing or unavailable.")
    }
    
    func testNSError() {
        var error: NSError?
        var userInfo: NSDictionary?
        
        error = IDXClientError.invalidClient as NSError
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 1)

        error = IDXClientError.serverError(message: "Message", localizationKey: "loc_key", type: "type") as NSError
        userInfo = NSDictionary(dictionary: ["message": "Message", "localizationKey": "loc_key", "type": "type"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 7)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

        error = IDXClientError.invalidParameter(name: "name") as NSError
        userInfo = NSDictionary(dictionary: ["name": "name"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 8)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

        error = IDXClientError.invalidParameterValue(name: "name", type: "type") as NSError
        userInfo = NSDictionary(dictionary: ["name": "name", "type": "type"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 9)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

        error = IDXClientError.parameterImmutable(name: "name") as NSError
        userInfo = NSDictionary(dictionary: ["name": "name"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 10)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

        error = IDXClientError.missingRequiredParameter(name: "name") as NSError
        userInfo = NSDictionary(dictionary: ["name": "name"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 11)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

        error = IDXClientError.unknownRemediationOption(name: "name") as NSError
        userInfo = NSDictionary(dictionary: ["name": "name"])
        XCTAssertEqual(error?.domain, "IDXClientError")
        XCTAssertEqual(error?.code, 12)
        XCTAssertEqual(error?.userInfo as NSDictionary?, userInfo)

    }
}
