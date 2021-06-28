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

class IDXExtractFormValueTests: XCTestCase {
    typealias Form = IDXClient.Remediation.Form

    func testPlainDefaultValues() throws {
        let form = try XCTUnwrap(Form(fields: [
            Form.Field(name: "stateHandle",
                       value: "abcEasyAs123" as AnyObject,
                       visible: false,
                       mutable: false,
                       required: true,
                       secret: false)
        ]))
        let result = try form.formValues()
        XCTAssertEqual(result as? [String:String], [
            "stateHandle": "abcEasyAs123"
        ])
    }

    func testPlainWithAdditiveValues() throws {
        let form = try XCTUnwrap(Form(fields: [
            Form.Field(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            Form.Field(name: "identifier",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false)
        ]))
        form["identifier"]?.value = "me@example.com"
        let result = try form.formValues()
        XCTAssertEqual(result as? [String:String], [
            "stateHandle": "abcEasyAs123",
            "identifier": "me@example.com"
        ])
    }

    func testNestedWithRootDefaults() throws {
        let form = try XCTUnwrap(Form(fields: [
            Form.Field(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            Form.Field(name: "credentials",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      form: Form(fields: [
                        Form.Field(name: "passcode",
                                  label: "Password",
                                  visible: true,
                                  mutable: true,
                                  required: true,
                                  secret: true)
                      ]))
        ]))
        form["credentials.passcode"]?.value = "password"
        
        let result = try form.formValues()
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["credentials"] as? [String:String], [ "passcode": "password" ])
    }

    func testNestedWithNestedDefaults() throws {
        let nestedForm = Form.Field(label: "Security Question",
                                   visible: true,
                                   mutable: true,
                                   required: true,
                                   secret: true,
                                   form: Form(fields: [
                                    Form.Field(name: "id",
                                              value: "idvalue" as AnyObject,
                                              visible: true,
                                              mutable: false,
                                              required: true,
                                              secret: false),
                                    Form.Field(name: "methodType",
                                              value: "security_question" as AnyObject,
                                              visible: true,
                                              mutable: false,
                                              required: false,
                                              secret: false)
                                   ]))
        let form = try XCTUnwrap(Form(fields: [
            Form.Field(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            Form.Field(name: "authenticator",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      options: [nestedForm])
        ]))
        form["authenticator"]?.selectedOption = nestedForm
        
        let result = try form.formValues()
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["authenticator"] as? [String:String], [
            "id": "idvalue",
            "methodType": "security_question"
        ])
    }

    func testNestedWithNestedDefaultsAndValues() throws {
        let smsOption = Form.Field(label: "SMS",
                                   value: "sms" as AnyObject,
                                   visible: true,
                                   mutable: true,
                                   required: false,
                                   secret: false)
        let voiceOption = Form.Field(label: "Voice call",
                                     value: "voice" as AnyObject,
                                     visible: true,
                                     mutable: true,
                                     required: false,
                                     secret: false)
        let nestedForm = Form.Field(label: "Phone",
                                    visible: true,
                                    mutable: true,
                                    required: true,
                                    secret: true,
                                    form: Form(fields: [
                                        Form.Field(name: "id",
                                                   value: "idvalue" as AnyObject,
                                                   visible: true,
                                                   mutable: false,
                                                   required: true,
                                                   secret: false),
                                        Form.Field(name: "methodType",
                                                   type: "string",
                                                   visible: true,
                                                   mutable: true,
                                                   required: false,
                                                   secret: false,
                                                   options: [ smsOption, voiceOption ]),
                                        Form.Field(name: "phoneNumber",
                                                   label: "Phone number",
                                                   visible: true,
                                                   mutable: true,
                                                   required: false,
                                                   secret: false),
                                    ]))
        let form = try XCTUnwrap(Form(fields: [
            Form.Field(name: "stateHandle",
                      value: "abcEasyAs123" as AnyObject,
                      visible: false,
                      mutable: false,
                      required: true,
                      secret: false),
            Form.Field(name: "authenticator",
                      type: "object",
                      visible: true,
                      mutable: true,
                      required: true,
                      secret: false,
                      options: [ nestedForm ])
        ]))
        form["authenticator"]?.selectedOption = nestedForm
        nestedForm.form?["methodType"]?.selectedOption = smsOption
        nestedForm.form?["phoneNumber"]?.value = "+1 123-555-1234"
        
        let result = try form.formValues()
        XCTAssertEqual(result["stateHandle"] as? String, "abcEasyAs123")
        XCTAssertEqual(result["authenticator"] as? [String:String], [
            "id": "idvalue",
            "methodType": "sms",
            "phoneNumber": "+1 123-555-1234"
        ])
    }
}
