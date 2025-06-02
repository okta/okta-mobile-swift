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

import XCTest
@testable import AuthFoundation
import TestCommon

struct TestStringArrayClaimProperty {
    @ClaimCollection
    var values: [String]
}

struct TestEnumArrayClaimProperty {
    enum Role: String, Equatable, ClaimConvertable, APIRequestArgument {
        case admin, superuser, user, guest

        static func convert(value: TestEnumArrayClaimProperty.Role?) -> Any? {
            value?.rawValue
        }
    }
    
    @ClaimCollection
    var values: [Role]
}

struct TestOptionalStringArrayClaimProperty {
    @ClaimCollection
    var values: [String]?
}

final class ClaimCollectionTests: XCTestCase {
    func testStringClaimCollectionPropertyWrapper() throws {
        var value = TestStringArrayClaimProperty(values: [])
        XCTAssertEqual(value.values, [])
        XCTAssertEqual(value.$values.rawValue, "")
        
        value.values = ["a", "b", "c"]
        XCTAssertEqual(value.values, ["a", "b", "c"])
        XCTAssertEqual(value.$values.wrappedValue, ["a", "b", "c"])
        XCTAssertEqual(value.$values.rawValue, "a b c")
        
        value.values.remove(at: 1)
        XCTAssertEqual(value.values, ["a", "c"])
        XCTAssertEqual(value.$values.wrappedValue, ["a", "c"])
        XCTAssertEqual(value.$values.rawValue, "a c")
        
        value.values.append("a")
        XCTAssertEqual(value.values, ["a", "c", "a"])
        XCTAssertEqual(value.$values.wrappedValue, ["a", "c", "a"])
        XCTAssertEqual(value.$values.rawValue, "a c a")
        
        var optional = TestOptionalStringArrayClaimProperty(values: nil)
        XCTAssertNil(optional.values)
        XCTAssertNil(optional.$values.rawValue)

        optional.values = ["a"]
        XCTAssertEqual(optional.values, ["a"])
        XCTAssertEqual(optional.$values.wrappedValue, ["a"])
        XCTAssertEqual(optional.$values.rawValue, "a")
        
        optional.values?.append(contentsOf: ["b", "c"])
        XCTAssertEqual(optional.values, ["a", "b", "c"])
        XCTAssertEqual(optional.$values.wrappedValue, ["a", "b", "c"])
        XCTAssertEqual(optional.$values.rawValue, "a b c")
    }

    func testEnumClaimCollectionPropertyWrapper() throws {
        var value = TestEnumArrayClaimProperty(values: [])
        XCTAssertEqual(value.values, [])
        XCTAssertEqual(value.$values.rawValue, "")
        
        value.values = [.admin, .guest]
        XCTAssertEqual(value.values, [.admin, .guest])
        XCTAssertEqual(value.$values.wrappedValue, [.admin, .guest])
        XCTAssertEqual(value.$values.rawValue, "admin guest")
        
        value.values.remove(at: 1)
        XCTAssertEqual(value.values, [.admin])
        XCTAssertEqual(value.$values.wrappedValue, [.admin])
        XCTAssertEqual(value.$values.rawValue, "admin")
        
        value.values.append(.admin)
        XCTAssertEqual(value.values, [.admin, .admin])
        XCTAssertEqual(value.$values.wrappedValue, [.admin, .admin])
        XCTAssertEqual(value.$values.rawValue, "admin admin")
        
        value = TestEnumArrayClaimProperty(values: [.admin, .superuser])
        XCTAssertEqual(value.values, [.admin, .superuser])
        XCTAssertEqual(value.$values.rawValue, "admin superuser")
    }
    
    func testStringClaimCollectionVariable() throws {
        var list = ClaimCollection<[String]>()
        XCTAssertEqual(list.rawValue, "")
        
        list.wrappedValue = ["a", "b", "c"]
        XCTAssertEqual(list.rawValue, "a b c")
        
        list.wrappedValue.removeAll()
        XCTAssertEqual(list.rawValue, "")
        
        list = ClaimCollection<[String]>(wrappedValue: ["x", "y", "z"])
        XCTAssertEqual(list.rawValue, "x y z")

        list = try XCTUnwrap(ClaimCollection<[String]>(rawValue: "red green blue"))
        XCTAssertEqual(list.rawValue, "red green blue")

        list = ["1", "2", "3"]
        XCTAssertEqual(list.rawValue, "1 2 3")
        
        list = "one two three"
        XCTAssertEqual(list.rawValue, "one two three")
    }

    func testEnumClaimCollectionVariable() throws {
        var list = ClaimCollection<[TestEnumArrayClaimProperty.Role]>()
        XCTAssertEqual(list.rawValue, "")
        
        list.wrappedValue = [.admin, .guest, .user]
        XCTAssertEqual(list.rawValue, "admin guest user")
        
        list.wrappedValue.removeAll()
        XCTAssertEqual(list.rawValue, "")
        
        list = ClaimCollection<[TestEnumArrayClaimProperty.Role]>(wrappedValue: [.superuser, .admin])
        XCTAssertEqual(list.rawValue, "superuser admin")

        list = try XCTUnwrap(ClaimCollection<[TestEnumArrayClaimProperty.Role]>(rawValue: "user guest"))
        XCTAssertEqual(list, [.user, .guest])
        XCTAssertEqual(list.rawValue, "user guest")

        list = [.admin, .user]
        XCTAssertEqual(list.rawValue, "admin user")
        
        list = "guest user"
        XCTAssertEqual(list, [.guest, .user])
        XCTAssertEqual(list.rawValue, "guest user")
    }

    func testCodableCollection() throws {
        let list = ClaimCollection<[String]>(wrappedValue: ["a", "b", "c"])
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]>.self, from: data)
        XCTAssertEqual(list, result)
    }

    func testCodableOptionalCollection() throws {
        let list = ClaimCollection<[String]?>(wrappedValue: ["a", "b", "c"])
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]?>.self, from: data)
        XCTAssertEqual(list, result)
    }

    func testCodableNilOptionalCollection() throws {
        let list = ClaimCollection<[String]?>(wrappedValue: nil)
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]?>.self, from: data)
        XCTAssertEqual(list, result)
    }
}
