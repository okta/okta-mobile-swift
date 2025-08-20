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
import Testing
import CommonSupport
@testable import JSON

fileprivate struct TestCodable: Codable {
    let firstName: String
    let lastName: String
    let commentCount: Int
}

struct JSONTests {
    @Test("Mutating object values")
    func testObjectMutation() throws {
        var json = JSON([:])
        #expect(json.value == .object([:]))
        #expect(json.representation == .json(.object([:])))
        
        json["name"] = "alex"
        #expect(json.value == .object([
            "name": JSON.Value.primitive(.string("alex")),
        ]))
        
        json["isEngineer"] = true
        #expect(json.value == .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
        ]))
        
        json["tags"] = ["swift", "employee"]
        #expect(json.value == .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee"))]),
        ]))
        
        json["tags"]?.array?.append("colleague")
        #expect(json.value == .object([
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee")),
                                      .primitive(.string("colleague"))]),
        ]))
        #expect(json.object == [
            "name": JSON.Value.primitive(.string("alex")),
            "isEngineer": JSON.Value.primitive(.bool(true)),
            "tags": JSON.Value.array([.primitive(.string("swift")),
                                      .primitive(.string("employee")),
                                      .primitive(.string("colleague"))]),
        ])

        json["isEngineer"] = nil
        #expect(json["isEngineer"] == .null)

        json.value = .array([1, 2, 3])
        #expect(json.value == .array([.primitive(1), .primitive(2), .primitive(3)]))
    }
    
    @Test("Mutating array values")
    func testArrayMutation() throws {
        var json = JSON([])
        #expect(json.value == .array([]))
        #expect(json.representation == .json(.array([])))
        
        json.value.array?.append(1)
        #expect(json[0] == .primitive(.int(1)))

        json[0] = "Apple"
        #expect(json[0] == .primitive(.string("Apple")))
        
        #expect(json.array == ["Apple"])
        #expect(json.object == nil)
        
        json[0] = nil
        #expect(json[0] == .null)
    }
    
    @Test("Subscripts")
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
        
        #expect(json["rp"]?["name"] == "example-org-name")
        #expect(json["pubKeyCredParams"]?[0]?["alg"] == -7)
        #expect(json["pubKeyCredParams"]?.array?.first?["alg"] == -7)
    }
    
    @Test("JSON initializers")
    func testInitializers() throws {
        var json: JSON
        
        // JSON data initialization
        json = try JSON(Data("{\"name\":\"alex\"}".utf8))
        #expect(json.value == ["name": "alex"])
        
        // JSON string initialization
        json = try JSON("{\"name\":\"zaphod\"}")
        #expect(json.value == ["name": "zaphod"])
        
        // JSON `Value` initialization (non-throwing)
        json = JSON(.object(["name": "arthur"]))
        #expect(json.value == ["name": "arthur"])
        
        // JSON `Any` initialization
        json = try JSON(["name": "trillian"])
        #expect(json.value == ["name": "trillian"])
        
        // JSON map values from `Any`
        json = try JSON([1, 2, 3, 4])
        #expect(json.value == [1, 2, 3, 4])
        
        // JSON initialization via `Codable`
        let codableObject = TestCodable(firstName: "Alex", lastName: "Nachbaur", commentCount: 15)
        json = try JSON(codableObject)
        #expect(json.value == .object([
            "firstName": "Alex",
            "lastName": "Nachbaur",
            "commentCount": 15,
        ]))
        
        #expect(throws: (any Error).self) {
            try JSON("this is a string")
        }
        
        var error = #expect(throws: JSONError.self) {
            try JSON(1234)
        }
        #expect(error == .unsupportedRootValue)
        
        error = #expect(throws: JSONError.self) {
            try JSON(3.15)
        }
        #expect(error == .unsupportedRootValue)
        
        error = #expect(throws: JSONError.self) {
            try JSON(true)
        }
        #expect(error == .unsupportedRootValue)
    }
    
    @Test("Primitive initializers")
    func testPrimitiveInitializers() throws {
        #expect(JSON.Primitive.string("String value") == "String value")
        #expect(JSON.Primitive.int(1234) == 1234)
        #expect(JSON.Primitive.double(3.14) == 3.14)
        #expect(JSON.Primitive.bool(true) == true)
        #expect(JSON.Primitive.init(nilLiteral: ()) == nil)
        
        #expect(true.primitive == JSON.Primitive.bool(true))
        #expect("Hello, world!".primitive == JSON.Primitive.string("Hello, world!"))
        #expect(42.primitive == JSON.Primitive.int(42))
        #expect(3.15.primitive == JSON.Primitive.double(3.15))
        #expect(JSON.Primitive.bool(true).primitive == .bool(true))
        
        let value = NSNull()
        #expect(value.primitive == JSON.Primitive.null)
    }
    
    @Test("Value initializers")
    func testValueInitializers() throws {
        #expect(JSON.Value.primitive(.string("String value")) == "String value")
        #expect(JSON.Value.primitive(.int(1234)) == 1234)
        #expect(JSON.Value.primitive(.double(3.14)) == 3.14)
        #expect(JSON.Value.primitive(.bool(true)) == true)
        #expect(JSON.Value.primitive(.init(nilLiteral: ())) == nil)
        #expect(JSON.Value.array([
            .primitive(.string("Foo")),
            .primitive("Bar"),
        ]) == ["Foo", "Bar"])
        #expect(JSON.Value.object([
            "Foo": .primitive(.string("Bar")),
        ]) == ["Foo": "Bar"])

        
        #expect(true.jsonValue == JSON.Value.primitive(.bool(true)))
        #expect("Hello, world!".jsonValue == JSON.Value.primitive(.string("Hello, world!")))
        #expect(42.jsonValue == JSON.Value.primitive(.int(42)))
        #expect(3.15.jsonValue == JSON.Value.primitive(.double(3.15)))
        #expect(JSON.Primitive.bool(true).jsonValue == .primitive(.bool(true)))
        #expect(JSON.Value.primitive(.bool(true)).jsonValue == .primitive(.bool(true)))

        let value = NSNull()
        #expect(value.jsonValue == JSON.Value.null)
    }
    
    @Test("Value accessors")
    func testValueAccessors() throws {
        var value: JSON.Value = .null
        #expect(value.isNull)
        #expect(value == .null)

        value.string = "Hello, world!"
        #expect(value == .primitive(.string("Hello, world!")))
        #expect(value.string == "Hello, world!")
        #expect(value.array == nil)
        #expect(value.object == nil)

        value.string = nil
        #expect(value.string == nil)
        #expect(value == .null)
        
        value.int = 42
        #expect(value == .primitive(.int(42)))
        #expect(value.int == 42)
        #expect(value.array == nil)
        #expect(value.object == nil)
        value.int = nil
        #expect(value.int == nil)

        value.double = 3.15
        #expect(value == .primitive(.double(3.15)))
        #expect(value.double == 3.15)
        #expect(value.int == nil)
        #expect(value.array == nil)
        #expect(value.object == nil)
        value.double = nil
        #expect(value.double == nil)

        value.bool = true
        #expect(value == .primitive(.bool(true)))
        #expect(value.bool == true)
        #expect(value.int == nil)
        #expect(value.double == nil)
        #expect(value.array == nil)
        #expect(value.object == nil)
        value.bool = nil
        #expect(value.bool == nil)
        
        value.array = [1, 2, 3]
        #expect(value == .array([
            .primitive(.int(1)),
            .primitive(.int(2)),
            .primitive(.int(3)),
        ]))
        #expect(value.array == [1, 2, 3])
        #expect(value.int == nil)
        #expect(value.double == nil)
        
        value.array = nil
        #expect(value.array == nil)
        
        value.anyValue = "Hello, world!"
        #expect(value == .primitive(.string("Hello, world!")))
        #expect(value.anyValue as? String == "Hello, world!")
        #expect(value.string == "Hello, world!")
        #expect(value.int == nil)
        #expect(value.double == nil)
        #expect(value.bool == nil)
        #expect(value.array == nil)
        #expect(value.object == nil)

        value.anyValue = ["Hello, world!"]
        #expect(value == .array([.primitive(.string("Hello, world!"))]))
        #expect(value.anyValue as? [String] == ["Hello, world!"])
        #expect(value.array == ["Hello, world!"])
        #expect(value.int == nil)
        #expect(value.double == nil)
        #expect(value.bool == nil)
        #expect(value.object == nil)
        
        value.anyValue = JSON.Primitive.string("Hello, world!")
        #expect(value.string == "Hello, world!")

        value.anyValue = JSON.Value.primitive(.string("Hello, world!"))
        #expect(value.string == "Hello, world!")
    }
    
    @Test("Storage representation")
    func testRepresentation() throws {
        let data = Data("{\"name\":\"zaphod\"}".utf8)
        
        var json = try JSON(data)
        var json2 = json
        #expect(json.storage === json2.storage)
        #expect(try json.data == Data("""
            {"name":"zaphod"}
            """.utf8))
        
        #expect(json.storage.value.representation == .data(data))
        #expect(json.storage.value.value == .object([
            "name": JSON.Value.primitive(.string("zaphod")),
        ]))

        json["isActive"] = true
        #expect(json.storage.value.representation == .json(.object([
            "name": JSON.Value.primitive(.string("zaphod")),
            "isActive": JSON.Value.primitive(.bool(true))
        ])))
        #expect(json.storage.value.value == .object([
            "name": JSON.Value.primitive(.string("zaphod")),
            "isActive": JSON.Value.primitive(.bool(true))
        ]))
        #expect(json.storage !== json2.storage)

        let encodedData: Data = try json.encode()
        #expect(json.storage.value.representation == .data(encodedData))

        #expect(try json.encode() == """
            {"isActive":true,"name":"zaphod"}
            """)
        
        // Test implicit rendering of `value` representations
        json2["name"] = "arthur"
        #expect(try json2.data == Data("""
            {"name":"arthur"}
            """.utf8))
    }
}
