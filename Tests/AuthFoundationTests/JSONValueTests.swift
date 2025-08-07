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

import Foundation
import Testing
@testable import AuthFoundation
@testable import TestCommon

@Suite("JSON Value Serialization and Type Handling", .disabled("Debugging test deadlocks within CI"))
struct JSONTests {
    var decoder: JSONDecoder { JSONDecoder() }
    var encoder: JSONEncoder { JSONEncoder() }
    
    @Test("String JSON value creation and serialization")
    func testString() throws {
        let value = JSON.string("Test String")
        #expect(value.debugDescription == "\"Test String\"")
        
        if let stringValue = value.anyValue as? String {
            #expect(stringValue == "Test String")
        } else {
            Issue.record("Object not a string")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Integer JSON value creation and serialization")
    func testInt() throws {
        let value = JSON.number(1)
        #expect(value.debugDescription == "1")
        
        if let numberValue = value.anyValue as? NSNumber {
            #expect(numberValue == NSNumber(integerLiteral: 1))
        } else {
            Issue.record("Object not a number")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Double JSON value creation and serialization")
    func testDouble() throws {
        let value = JSON.number(1.5)
        #expect(value.debugDescription == "1.5")
        
        if let numberValue = value.anyValue as? NSNumber {
            #expect(numberValue == NSNumber(floatLiteral: 1.5))
        } else {
            Issue.record("Object not a number")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Boolean JSON value creation and serialization")
    func testBool() throws {
        let value = JSON.bool(true)
        #expect(value.debugDescription == "true")
        #expect(JSON.bool(false).debugDescription == "false")

        if let boolValue = value.anyValue as? NSNumber {
            #expect(boolValue == NSNumber(booleanLiteral: true))
        } else {
            Issue.record("Object not a bool")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Null JSON value creation and serialization")
    func testNull() throws {
        let value = JSON.null
        #expect(value.debugDescription == "null")
        
        #expect(value.anyValue == nil)
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Array JSON value creation and serialization")
    func testArray() throws {
        let value = JSON.array([JSON.string("foo"), JSON.string("bar")])
        #expect(value.debugDescription == """
            [
              "foo",
              "bar"
            ]
            """)
        
        if let arrayValue = value.anyValue as? NSArray {
            #expect(arrayValue == ["foo", "bar"])
        } else {
            Issue.record("Object not a array")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
    }
    
    @Test("Dictionary JSON value creation and nested structure serialization")
    func testDictionary() throws {
        let value = JSON.object(
            ["foo": JSON.object(
                ["bar": JSON.array(
                    [JSON.string("woof")])
                ])
            ])
        #expect(value.debugDescription == """
            {
              "foo" : {
                "bar" : [
                  "woof"
                ]
              }
            }
            """)
        if let dictValue = value.anyValue as? NSDictionary {
            #expect(dictValue == ["foo": ["bar": ["woof"]]])
        } else {
            Issue.record("Object not a dictionary")
        }
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSON.self, from: encoded)
        #expect(decoded == value)
        
        let asDictionary = try #require(value.anyValue as? [String: Any])
        let foo = try #require(asDictionary["foo"] as? [String: Any])
        let bar = try #require(foo["bar"] as? [String])
        #expect(bar.first == "woof")
    }

    func testConversions() throws {
        let json = try decoder.decode(JSON.self,
                                        from: try data(from: .module,
                                                       for: "openid-configuration",
                                                       in: "MockResponses"))
        let object = try #require(json.anyValue as? [String: Any])
        let array = try #require(object["claims_supported"] as? [String])
        
        #expect(array.count == 31)
    }
}
