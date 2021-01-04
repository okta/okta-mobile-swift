//
//  IDXClientV1ResponseTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-30.
//

import XCTest
@testable import OktaIdx

class IDXClientV1ResponseTests: XCTestCase {
    typealias API = IDXClient.APIVersion1
    
    func data(for json: String) -> Data {
        return json.data(using: .utf8)!
    }
    
    func decode<T>(type: T.Type, _ json: String) throws -> T where T : Decodable {
        let jsonData = data(for: json)
        return try JSONDecoder.idxResponseDecoder.decode(T.self, from: jsonData)
    }

    func decode<T>(type: T.Type, _ json: String, _ test: ((T) -> Void)) throws where T : Decodable {
        test(try decode(type: type, json))
    }

    func testForm() throws {
        let obj = try decode(type: API.Response.Form.self, """
        {
            "rel": ["create-form"],
            "name": "identify",
            "href": "https://example.com/idp/idx/identify",
            "method": "POST",
            "value": [
                {
                    "name": "identifier",
                    "label": "Username"
                }
            ],
            "accepts": "application/ion+json; okta-version=1.0.0"
        }
        """)
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj.rel, ["create-form"])
        XCTAssertEqual(obj.name, "identify")
        XCTAssertEqual(obj.href, URL(string: "https://example.com/idp/idx/identify")!)
        XCTAssertEqual(obj.method, "POST")
        XCTAssertEqual(obj.accepts, "application/ion+json; okta-version=1.0.0")
        
        XCTAssertEqual(obj.value.count, 1)
    }
    
    func testCompositeForm() throws {
        try decode(type: API.Response.CompositeForm.self, """
        {
          "form": {
            "value": [
              {
                "name": "id",
                "required": true,
                "value": "someCode",
                "mutable": false
              },
              {
                "name": "methodType",
                "required": false,
                "value": 1,
                "mutable": false
              }
            ]
          }
        }
        """) { obj in
            XCTAssertNotNil(obj.form)
            XCTAssertEqual(obj.form.value.count, 2)
            XCTAssertEqual(obj.form.value[0].name, "id")
            XCTAssertEqual(obj.form.value[0].value, .string("someCode"))
            XCTAssertEqual(obj.form.value[1].name, "methodType")
            XCTAssertEqual(obj.form.value[1].value, .number(1))

        }
    }
    
    func testFormValue() throws {
        try decode(type: API.Response.FormValue.self, """
        {
            "name": "identifier",
            "label": "Username"
        }
        """) { (obj) in
            XCTAssertNotNil(obj)
            XCTAssertEqual(obj.name, "identifier")
            XCTAssertEqual(obj.label, "Username")
            XCTAssertNil(obj.type)
            XCTAssertNil(obj.required)
            XCTAssertNil(obj.mutable)
            XCTAssertNil(obj.secret)
            XCTAssertNil(obj.visible)
            XCTAssertNil(obj.value)
        }
        
        try decode(type: API.Response.FormValue.self, """
        {
            "name": "stateHandle",
            "required": true,
            "value": "theStateHandle",
            "visible": false,
            "secret": false,
            "mutable": false
        }
        """) { (obj) in
            XCTAssertNotNil(obj)
            XCTAssertEqual(obj.name, "stateHandle")
            XCTAssertNil(obj.label)
            XCTAssertEqual(obj.value, .string("theStateHandle"))
            XCTAssertTrue(obj.required!)
            XCTAssertFalse(obj.visible!)
            XCTAssertFalse(obj.secret!)
            XCTAssertFalse(obj.mutable!)
        }

        try decode(type: API.Response.FormValue.self, """
          {
            "label": "Email",
            "value": {
              "form": {
                "value": [
                  {
                    "name": "id",
                    "required": true,
                    "value": "aut2ihzk1gHl7ynhd1d6",
                    "mutable": false
                  },
                  {
                    "name": "methodType",
                    "required": false,
                    "value": "email",
                    "mutable": false
                  }
                ]
              }
            },
            "relatesTo": "$.authenticatorEnrollments.value[0]"
          }
        """) { (obj) in
            XCTAssertNotNil(obj)
            XCTAssertEqual(obj.label, "Email")
            
            let form = obj.value?.toAnyObject() as? API.Response.CompositeForm
            XCTAssertNotNil(form)
            XCTAssertEqual(form?.form.value.count, 2)
        }

        try decode(type: API.Response.FormValue.self, """
          {
            "name": "authenticator",
            "type": "object",
            "options": [
              {
                "label": "Email"
              }
            ]
          }
        """) { (obj) in
            XCTAssertNotNil(obj)
            XCTAssertEqual(obj.name, "authenticator")
            XCTAssertEqual(obj.type, "object")
            XCTAssertNotNil(obj.options)
            XCTAssertEqual(obj.options?.count, 1)
        }

    }
}
