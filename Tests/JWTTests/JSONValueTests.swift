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
@testable import JWT
import TestCommon

class JSONTests: XCTestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    static override func setUp() {
        registerMock(bundles: .jwtTests)
    }
    
    func testString() throws {
        let value = JSON.string("Test String")
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "\"Test String\"")
        
        if let stringValue = value.anyValue as? String {
            XCTAssertEqual(stringValue, "Test String")
        } else {
            XCTFail("Object not a string")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testInt() throws {
        let value = JSON.number(1)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "1")
        
        if let numberValue = value.anyValue as? NSNumber {
            XCTAssertEqual(numberValue, NSNumber(integerLiteral: 1))
        } else {
            XCTFail("Object not a number")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testDouble() throws {
        let value = JSON.number(1.5)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "1.5")
        
        if let numberValue = value.anyValue as? NSNumber {
            XCTAssertEqual(numberValue, NSNumber(floatLiteral: 1.5))
        } else {
            XCTFail("Object not a number")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testBool() throws {
        let value = JSON.bool(true)
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "true")
        XCTAssertEqual(JSON.bool(false).debugDescription, "false")

        if let boolValue = value.anyValue as? NSNumber {
            XCTAssertEqual(boolValue, NSNumber(booleanLiteral: true))
        } else {
            XCTFail("Object not a bool")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testNull() throws {
        let value = JSON.null
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "null")
        
        XCTAssertNil(value.anyValue)
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testArray() throws {
        let value = JSON.array([JSON.string("foo"), JSON.string("bar")])
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
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testDictionary() throws {
        let value = JSON.object(
            ["foo": JSON.object(
                ["bar": JSON.array(
                    [JSON.string("woof")])
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
        let decoded = try decoder.decode(JSON.self, from: encoded)
        XCTAssertEqual(decoded, value)
        
        let asDictionary = try XCTUnwrap(value.anyValue as? [String: Any])
        let foo = try XCTUnwrap(asDictionary["foo"] as? [String: Any])
        let bar = try XCTUnwrap(foo["bar"] as? [String])
        XCTAssertEqual(bar.first, "woof")
    }
    
    func testConversions() throws {
        let json = try decoder.decode(JSON.self,
                                      from: try data(filename: "openid-configuration"))
        let object = try XCTUnwrap(json.anyValue as? [String: Any])
        let array = try XCTUnwrap(object["claims_supported"] as? [String])
        
        XCTAssertEqual(array.count, 31)
    }
}
