//
//  JSONValueTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-16.
//

import XCTest
@testable import OktaIdx

class JSONValueTests: XCTestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    func testString() throws {
        let value = JSONValue.string("Test String")
        XCTAssertNotNil(value)
        XCTAssertEqual(value.debugDescription, "\"Test String\"")
        
        if let stringValue = value.toAnyObject() as? String {
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
        
        if let numberValue = value.toAnyObject() as? NSNumber {
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

        if let boolValue = value.toAnyObject() as? NSNumber {
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
        
        if let nullValue = value.toAnyObject() as? NSNull {
            XCTAssertEqual(nullValue, NSNull())
        } else {
            XCTFail("Object not a null")
        }
        
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
        
        if let arrayValue = value.toAnyObject() as? NSArray {
            XCTAssertEqual(arrayValue, ["foo", "bar"])
        } else {
            XCTFail("Object not a array")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
    
    func testObject() throws {
        let value = JSONValue.object(
            ["foo": JSONValue.object(
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
        if let dictValue = value.toAnyObject() as? NSDictionary {
            XCTAssertEqual(dictValue, ["foo": ["bar": ["woof"]]])
        } else {
            XCTFail("Object not a dictionary")
        }
        
        let encoded = try encoder.encode(value)
        XCTAssertNotNil(encoded)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        XCTAssertEqual(decoded, value)
    }
}
