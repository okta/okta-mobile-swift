/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
