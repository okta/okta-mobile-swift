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
@testable import AuthFoundation

class JSONValueTests: XCTestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    func testString() throws {
        let value = JSONValue.string("Test String")
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "\"Test String\"")
        
        if let stringValue = value.anyValue as? String {
            XCTAssertEqual(stringValue, "Test String")
        } else {
            XCTFail("Object not a string")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testNumber() throws {
        let value = JSONValue.number(1)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "1.0")
        
        if let numberValue = value.anyValue as? NSNumber {
            XCTAssertEqual(numberValue, NSNumber(integerLiteral: 1))
        } else {
            XCTFail("Object not a number")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testBool() throws {
        let value = JSONValue.bool(true)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "true")
        XCTAssertEqual(JSONValue.bool(false).debugDescription, "false")

        if let boolValue = value.anyValue as? NSNumber {
            XCTAssertEqual(boolValue, NSNumber(booleanLiteral: true))
        } else {
            XCTFail("Object not a bool")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testNull() throws {
        let value = JSONValue.null
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "null")
        
        XCTAssertNil(value.anyValue)
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testArray() throws {
        let value = JSONValue.array([JSONValue.string("foo"), JSONValue.string("bar")])
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, """
            [
              "foo",
              "bar"
            ]
            """)
        
        if let arrayValue = value.anyValue as? NSArray {
            XCTAssertEqual(arrayValue, ["foo", "bar"])
        } else {
            XCTFail("Object not a array")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testDictionary() throws {
        let value = JSONValue.dictionary(
            ["foo": JSONValue.dictionary(
                ["bar": JSONValue.array(
                    [JSONValue.string("woof")])
                ])
            ])
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, """
            {
              "foo" : {
                "bar" : [
                  "woof"
                ]
              }
            }
            """)
        if let dictValue = value.anyValue as? NSDictionary {
            XCTAssertEqual(dictValue, ["foo": ["bar": ["woof"]]])
        } else {
            XCTFail("Object not a dictionary")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testObject() throws {
        let object = URL(string: "https://example.com")!
        let value = JSONValue.object(object)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "https://example.com")

        if let urlValue = value.anyValue as? URL {
            XCTAssertEqual(urlValue, URL(string: "https://example.com"))
        } else {
            XCTFail("Object not a URL")
        }
        
        XCTAssertEqual(value, JSONValue.object(URL(string: "https://example.com")!))
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded.anyValue as? String, "https://example.com")
    }
}
