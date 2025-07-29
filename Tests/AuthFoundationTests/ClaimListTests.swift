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

@Suite("ClaimCollection tests")
struct ClaimCollectionTests {
    @Test("String claim collection property wrapper")
    func testStringClaimCollectionPropertyWrapper() throws {
        var value = TestStringArrayClaimProperty(values: [])
        #expect(value.values == [])
        #expect(value.$values.rawValue == "")
        
        value.values = ["a", "b", "c"]
        #expect(value.values == ["a", "b", "c"])
        #expect(value.$values.wrappedValue == ["a", "b", "c"])
        #expect(value.$values.rawValue == "a b c")
        
        value.values.remove(at: 1)
        #expect(value.values == ["a", "c"])
        #expect(value.$values.wrappedValue == ["a", "c"])
        #expect(value.$values.rawValue == "a c")
        
        value.values.append("a")
        #expect(value.values == ["a", "c", "a"])
        #expect(value.$values.wrappedValue == ["a", "c", "a"])
        #expect(value.$values.rawValue == "a c a")
        
        var optional = TestOptionalStringArrayClaimProperty(values: nil)
        #expect(optional.values == nil)
        #expect(optional.$values.rawValue == nil)

        optional.values = ["a"]
        #expect(optional.values == ["a"])
        #expect(optional.$values.wrappedValue == ["a"])
        #expect(optional.$values.rawValue == "a")
        
        optional.values?.append(contentsOf: ["b", "c"])
        #expect(optional.values == ["a", "b", "c"])
        #expect(optional.$values.wrappedValue == ["a", "b", "c"])
        #expect(optional.$values.rawValue == "a b c")
    }

    @Test("Enum claim collection property wrapper")
    func testEnumClaimCollectionPropertyWrapper() throws {
        var value = TestEnumArrayClaimProperty(values: [])
        #expect(value.values == [])
        #expect(value.$values.rawValue == "")
        
        value.values = [.admin, .guest]
        #expect(value.values == [.admin, .guest])
        #expect(value.$values.wrappedValue == [.admin, .guest])
        #expect(value.$values.rawValue == "admin guest")
        
        value.values.remove(at: 1)
        #expect(value.values == [.admin])
        #expect(value.$values.wrappedValue == [.admin])
        #expect(value.$values.rawValue == "admin")
        
        value.values.append(.admin)
        #expect(value.values == [.admin, .admin])
        #expect(value.$values.wrappedValue == [.admin, .admin])
        #expect(value.$values.rawValue == "admin admin")
        
        value = TestEnumArrayClaimProperty(values: [.admin, .superuser])
        #expect(value.values == [.admin, .superuser])
        #expect(value.$values.rawValue == "admin superuser")
    }
    
    @Test("String claim collection variable")
    func testStringClaimCollectionVariable() throws {
        var list = ClaimCollection<[String]>()
        #expect(list.rawValue == "")
        
        list.wrappedValue = ["a", "b", "c"]
        #expect(list.rawValue == "a b c")
        
        list.wrappedValue.removeAll()
        #expect(list.rawValue == "")
        
        list = ClaimCollection<[String]>(wrappedValue: ["x", "y", "z"])
        #expect(list.rawValue == "x y z")

        list = ClaimCollection<[String]>(rawValue: "red green blue")
        #expect(list.rawValue == "red green blue")

        list = ["1", "2", "3"]
        #expect(list.rawValue == "1 2 3")
        
        list = "one two three"
        #expect(list.rawValue == "one two three")
    }

    @Test("Enum claim collection variable")
    func testEnumClaimCollectionVariable() throws {
        var list = ClaimCollection<[TestEnumArrayClaimProperty.Role]>()
        #expect(list.rawValue == "")
        
        list.wrappedValue = [.admin, .guest, .user]
        #expect(list.rawValue == "admin guest user")
        
        list.wrappedValue.removeAll()
        #expect(list.rawValue == "")
        
        list = ClaimCollection<[TestEnumArrayClaimProperty.Role]>(wrappedValue: [.superuser, .admin])
        #expect(list.rawValue == "superuser admin")

        list = ClaimCollection<[TestEnumArrayClaimProperty.Role]>(rawValue: "user guest")
        #expect(list == [.user, .guest])
        #expect(list.rawValue == "user guest")

        list = [.admin, .user]
        #expect(list.rawValue == "admin user")
        
        list = "guest user"
        #expect(list == [.guest, .user])
        #expect(list.rawValue == "guest user")
    }

    @Test("Codable collection")
    func testCodableCollection() throws {
        let list = ClaimCollection<[String]>(wrappedValue: ["a", "b", "c"])
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]>.self, from: data)
        #expect(list == result)
    }

    @Test("Codable optional collection")
    func testCodableOptionalCollection() throws {
        let list = ClaimCollection<[String]?>(wrappedValue: ["a", "b", "c"])
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]?>.self, from: data)
        #expect(list == result)
    }

    @Test("Codable nil optional collection")
    func testCodableNilOptionalCollection() throws {
        let list = ClaimCollection<[String]?>(wrappedValue: nil)
        let data = try JSONEncoder().encode(list)
        let result = try JSONDecoder().decode(ClaimCollection<[String]?>.self, from: data)
        #expect(list == result)
    }
}
