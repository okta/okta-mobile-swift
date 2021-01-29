//
//  IDXExtractFormValueTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-01-27.
//

import XCTest
@testable import OktaIdx

class IDXExtractFormValueTests: XCTestCase {
    typealias FormValue = IDXClient.Remediation.FormValue

    func testPlainDefaultValues() throws {
        let form = [
            FormValue(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false)
        ]
        let result = try IDXClient.extractFormValues(from: form)
        XCTAssertEqual(result as? [String:String], [
            "stateHandle": "abcEasyAs123"
        ])
    }

    func testPlainWithAdditiveValues() throws {
        let form = [
            FormValue(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            FormValue(name: "identifier",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false)
        ]
        let result = try IDXClient.extractFormValues(from: form,
                                                     with: ["identifier": "me@example.com"])
        XCTAssertEqual(result as? [String:String], [
            "stateHandle": "abcEasyAs123",
            "identifier": "me@example.com"
        ])
    }

    func testNestedWithRootDefaults() throws {
        let form = [
            FormValue(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            FormValue(name: "credentials",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      form: [
                        FormValue(name: "passcode",
                                  label: "Password",
                                  visible: true,
                                  mutable: true,
                                  required: true,
                                  secret: true)
                      ])
        ]
        
        let result = try IDXClient.extractFormValues(from: form,
                                                     with: ["credentials": ["passcode": "password"]])
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["credentials"] as? [String:String], [ "passcode": "password" ])
    }

    func testNestedWithNestedDefaults() throws {
        let nestedForm = FormValue(label: "Security Question",
                                   visible: true,
                                   mutable: true,
                                   required: true,
                                   secret: true,
                                   form: [
                                    FormValue(name: "id",
                                              value: "idvalue" as AnyObject,
                                              visible: true,
                                              mutable: false,
                                              required: true,
                                              secret: false),
                                    FormValue(name: "methodType",
                                              value: "security_question" as AnyObject,
                                              visible: true,
                                              mutable: false,
                                              required: false,
                                              secret: false)
                                   ])
        let form = [
            FormValue(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            FormValue(name: "authenticator",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      options: [ nestedForm ])
        ]
        
        let result = try IDXClient.extractFormValues(from: form,
                                                     with: ["authenticator": nestedForm])
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["authenticator"] as? [String:String], [
            "id": "idvalue",
            "methodType": "security_question"
        ])
    }

    func testNestedWithNestedDefaultsAndValues() throws {
        let nestedForm = FormValue(label: "Phone",
                                   visible: true,
                                   mutable: true,
                                   required: true,
                                   secret: true,
                                   form: [
                                    FormValue(name: "id",
                                              value: "idvalue" as AnyObject,
                                              visible: true,
                                              mutable: false,
                                              required: true,
                                              secret: false),
                                    FormValue(name: "methodType",
                                              type: "string",
                                              visible: true,
                                              mutable: true,
                                              required: false,
                                              secret: false,
                                              options: [
                                                FormValue(label: "SMS",
                                                          value: "sms" as AnyObject,
                                                          visible: true,
                                                          mutable: true,
                                                          required: false,
                                                          secret: false),
                                                FormValue(label: "Voice call",
                                                          value: "voice" as AnyObject,
                                                          visible: true,
                                                          mutable: true,
                                                          required: false,
                                                          secret: false),
                                              ]),
                                    FormValue(name: "phoneNumber",
                                              label: "Phone number",
                                              visible: true,
                                              mutable: true,
                                              required: false,
                                              secret: false),
                                   ])
        let form = [
            FormValue(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            FormValue(name: "authenticator",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      options: [ nestedForm ])
        ]
        
        let result = try IDXClient.extractFormValues(from: form,
                                                     with: ["authenticator": nestedForm.formValues(with: ["methodType": "sms" ]) as Any])
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["authenticator"] as? [String:String], [
            "id": "idvalue",
            "methodType": "sms"
        ])
    }
}
