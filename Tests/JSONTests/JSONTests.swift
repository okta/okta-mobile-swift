//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import XCTest
import CommonSupport
@testable import JSON

fileprivate struct TestCodable: Codable {
    let firstName: String
    let lastName: String
    let commentCount: Int
}

final class JSONTests: XCTestCase {
    func testObjectMutation() throws {
        var json = JSON([:])
        XCTAssertEqual(json.value, .object([:]))
        XCTAssertEqual(json.representation, .json(.object([:])))
        
        json["name"] = "alex"
        XCTAssertEqual(json.value, .object([
            "name": JSON.Value.primitive(.string("alex")),
        ]))
        
        json["isEngineer"] = true
        XCTAssertEqual(json.value, .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
        ]))
        
        json["tags"] = ["swift", "employee"]
        XCTAssertEqual(json.value, .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee"))]),
        ]))
        
        json["tags"]?.array?.append("colleague")
        XCTAssertEqual(json.value, .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee")),
                                      .primitive(.string("colleague"))]),
        ]))
        XCTAssertEqual(json.object, [
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee")),
                                      .primitive(.string("colleague"))]),
        ])

        json["isEngineer"] = nil
        XCTAssertEqual(json["isEngineer"], .null)

        json.value = .array([1, 2, 3])
        XCTAssertEqual(json.value, .array([.primitive(1), .primitive(2), .primitive(3)]))
    }
    
    func testArrayMutation() throws {
        var json = JSON([])
        XCTAssertEqual(json.value, .array([]))
        XCTAssertEqual(json.representation, .json(.array([])))
        
        json.value.array?.append(1)
        XCTAssertEqual(json[0], .primitive(.int(1)))

        json[0] = "Apple"
        XCTAssertEqual(json[0], .primitive(.string("Apple")))
        
        XCTAssertEqual(json.array, ["Apple"])
        XCTAssertNil(json.object)
        
        json[0] = nil
        XCTAssertEqual(json[0], .null)
    }
    
    func testSubscripts() throws {
        let json = try JSON("""
            {
              "rp": {
                "name": "example-org-name"
              },
              "pubKeyCredParams": [
                {
                  "type": "public-key",
                  "alg": -7
                },
                {
                  "type": "public-key",
                  "alg": -257
                }
              ]
            }
        """)
        
        XCTAssertEqual(json["rp"]?["name"], "example-org-name")
        XCTAssertEqual(json["pubKeyCredParams"]?[0]?["alg"], -7)
        XCTAssertEqual(json["pubKeyCredParams"]?.array?.first?["alg"], -7)
    }
    
    func testInitializers() throws {
        var json: JSON
        
        // JSON data initialization
        json = try JSON(Data("{\"name\":\"alex\"}".utf8))
        XCTAssertEqual(json.value, ["name": "alex"])
        
        // JSON string initialization
        json = try JSON("{\"name\":\"zaphod\"}")
        XCTAssertEqual(json.value, ["name": "zaphod"])
        
        // JSON `Value` initialization (non-throwing)
        json = JSON(.object(["name": "arthur"]))
        XCTAssertEqual(json.value, ["name": "arthur"])
        
        // JSON `Any` initialization
        json = try JSON(["name": "trillian"])
        XCTAssertEqual(json.value, ["name": "trillian"])
        
        // JSON map values from `Any`
        json = try JSON([1, 2, 3, 4])
        XCTAssertEqual(json.value, [1, 2, 3, 4])
        
        // JSON initialization via `Codable`
        let codableObject = TestCodable(firstName: "Alex", lastName: "Nachbaur", commentCount: 15)
        json = try JSON(codableObject)
        XCTAssertEqual(json.value, .object([
            "firstName": "Alex",
            "lastName": "Nachbaur",
            "commentCount": 15,
        ]))
        
        XCTAssertThrowsError(try JSON("this is a string"))
        
        var error: (any Error)?
        do {
            _ = try JSON(1234)
        } catch let e {
            error = e
        }
        XCTAssertEqual(error as? JSONError, .unsupportedRootValue)
        
        error = nil
        do {
            _ = try JSON(3.15)
        } catch let e {
            error = e
        }
        XCTAssertEqual(error as? JSONError, .unsupportedRootValue)
        
        error = nil
        do {
            _ = try JSON(true)
        } catch let e {
            error = e
        }
        XCTAssertEqual(error as? JSONError, .unsupportedRootValue)
    }
    
    func testPrimitiveInitializers() throws {
        XCTAssertEqual(JSON.Primitive.string("String value"), "String value")
        XCTAssertEqual(JSON.Primitive.int(1234), 1234)
        XCTAssertEqual(JSON.Primitive.double(3.14), 3.14)
        XCTAssertEqual(JSON.Primitive.bool(true), true)
        XCTAssertEqual(JSON.Primitive.init(nilLiteral: ()), nil)
        
        XCTAssertEqual(true.primitive, JSON.Primitive.bool(true))
        XCTAssertEqual("Hello, world!".primitive, JSON.Primitive.string("Hello, world!"))
        XCTAssertEqual(42.primitive, JSON.Primitive.int(42))
        XCTAssertEqual(3.15.primitive, JSON.Primitive.double(3.15))
        XCTAssertEqual(JSON.Primitive.bool(true).primitive, .bool(true))
        
        let value = NSNull()
        XCTAssertEqual(value.primitive, JSON.Primitive.null)
    }
    
    func testValueInitializers() throws {
        XCTAssertEqual(JSON.Value.primitive(.string("String value")), "String value")
        XCTAssertEqual(JSON.Value.primitive(.int(1234)), 1234)
        XCTAssertEqual(JSON.Value.primitive(.double(3.14)), 3.14)
        XCTAssertEqual(JSON.Value.primitive(.bool(true)), true)
        XCTAssertEqual(JSON.Value.primitive(.init(nilLiteral: ())), nil)
        XCTAssertEqual(JSON.Value.array([
            .primitive(.string("Foo")),
            .primitive("Bar"),
        ]), ["Foo", "Bar"])
        XCTAssertEqual(JSON.Value.object([
            "Foo": .primitive(.string("Bar")),
        ]), ["Foo": "Bar"])

        
        XCTAssertEqual(true.jsonValue, JSON.Value.primitive(.bool(true)))
        XCTAssertEqual("Hello, world!".jsonValue, JSON.Value.primitive(.string("Hello, world!")))
        XCTAssertEqual(42.jsonValue, JSON.Value.primitive(.int(42)))
        XCTAssertEqual(3.15.jsonValue, JSON.Value.primitive(.double(3.15)))
        XCTAssertEqual(JSON.Primitive.bool(true).jsonValue, .primitive(.bool(true)))
        XCTAssertEqual(JSON.Value.primitive(.bool(true)).jsonValue, .primitive(.bool(true)))

        let value = NSNull()
        XCTAssertEqual(value.jsonValue, JSON.Value.null)
    }
    
    func testValueAccessors() throws {
        var value: JSON.Value = .null
        XCTAssertTrue(value.isNull)
        XCTAssertEqual(value, .null)

        value.string = "Hello, world!"
        XCTAssertEqual(value, .primitive(.string("Hello, world!")))
        XCTAssertEqual(value.string, "Hello, world!")
        XCTAssertNil(value.array)
        XCTAssertNil(value.object)

        value.string = nil
        XCTAssertNil(value.string)
        XCTAssertEqual(value, .null)
        
        value.int = 42
        XCTAssertEqual(value, .primitive(.int(42)))
        XCTAssertEqual(value.int, 42)
        XCTAssertNil(value.array)
        XCTAssertNil(value.object)
        value.int = nil
        XCTAssertNil(value.int)

        value.double = 3.15
        XCTAssertEqual(value, .primitive(.double(3.15)))
        XCTAssertEqual(value.double, 3.15)
        XCTAssertNil(value.int)
        XCTAssertNil(value.array)
        XCTAssertNil(value.object)
        value.double = nil
        XCTAssertNil(value.double)

        value.bool = true
        XCTAssertEqual(value, .primitive(.bool(true)))
        XCTAssertEqual(value.bool, true)
        XCTAssertNil(value.int)
        XCTAssertNil(value.double)
        XCTAssertNil(value.array)
        XCTAssertNil(value.object)
        value.bool = nil
        XCTAssertNil(value.bool)
        
        value.array = [1, 2, 3]
        XCTAssertEqual(value, .array([
            .primitive(.int(1)),
            .primitive(.int(2)),
            .primitive(.int(3)),
        ]))
        XCTAssertEqual(value.array, [1, 2, 3])
        XCTAssertNil(value.int)
        XCTAssertNil(value.double)
        
        value.array = nil
        XCTAssertNil(value.array)
        
        value.anyValue = "Hello, world!"
        XCTAssertEqual(value, .primitive(.string("Hello, world!")))
        XCTAssertEqual(value.anyValue as? String, "Hello, world!")
        XCTAssertEqual(value.string, "Hello, world!")
        XCTAssertNil(value.int)
        XCTAssertNil(value.double)
        XCTAssertNil(value.bool)
        XCTAssertNil(value.array)
        XCTAssertNil(value.object)

        value.anyValue = ["Hello, world!"]
        XCTAssertEqual(value, .array([.primitive(.string("Hello, world!"))]))
        XCTAssertEqual(value.anyValue as? [String], ["Hello, world!"])
        XCTAssertEqual(value.array, ["Hello, world!"])
        XCTAssertNil(value.int)
        XCTAssertNil(value.double)
        XCTAssertNil(value.bool)
        XCTAssertNil(value.object)
        
        value.anyValue = JSON.Primitive.string("Hello, world!")
        XCTAssertEqual(value.string, "Hello, world!")

        value.anyValue = JSON.Value.primitive(.string("Hello, world!"))
        XCTAssertEqual(value.string, "Hello, world!")
    }
    
    func testRepresentation() throws {
        let data = Data("{\"name\":\"zaphod\"}".utf8)
        
        var json = try JSON(data)
        var json2 = json
        XCTAssertTrue(json.storage === json2.storage)
        XCTAssertEqual(try json.data, Data("""
            {"name":"zaphod"}
            """.utf8))
        
        XCTAssertEqual(json.storage.value.representation, .data(data))
        XCTAssertEqual(json.storage.value.value, .object([
            "name": JSON.Value.primitive(.string("zaphod")),
        ]))

        json["isActive"] = true
        XCTAssertEqual(json.storage.value.representation, .json(.object([
            "name": JSON.Value.primitive(.string("zaphod")),
            "isActive": JSON.Value.primitive(.bool(true))
        ])))
        XCTAssertEqual(json.storage.value.value, .object([
            "name": JSON.Value.primitive(.string("zaphod")),
            "isActive": JSON.Value.primitive(.bool(true))
        ]))
        XCTAssertFalse(json.storage === json2.storage)

        let encodedData: Data = try json.encode()
        XCTAssertEqual(json.storage.value.representation, .data(encodedData))

        XCTAssertEqual(try json.encode(), """
            {"isActive":true,"name":"zaphod"}
            """)
        
        // Test implicit rendering of `value` representations
        json2["name"] = "arthur"
        XCTAssertEqual(try json2.data, Data("""
            {"name":"arthur"}
            """.utf8))
    }
}
