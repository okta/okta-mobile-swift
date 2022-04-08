//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

import XCTest
@testable import AuthFoundation
@testable import TestCommon

final class KeychainTests: XCTestCase {
    let serviceName = (#file as NSString).lastPathComponent
    var mock: MockKeychain!
    
    override func setUp() {
        mock = MockKeychain()
        Keychain.implementation = mock
    }
    
    override func tearDownWithError() throws {
        Keychain.implementation = KeychainImpl()
        mock = nil
    }

    func testItemSave() throws {
        let genericData = "This is generic data".data(using: .utf8)!
        let value = "This is value data".data(using: .utf8)!
        let query = [
            "acct": "testItemSave()",
            "class": "genp",
            "desc": "Description",
            "gena": genericData,
            "labl": "Label",
            "pdmn": "cku",
            "nleg": 1,
            "sync": 1,
            "svce": "KeychainTests.swift",
            "v_Data": value
        ] as CFDictionary
        mock.expect(errSecItemNotFound)
        mock.expect(noErr)

        let item = Keychain.Item(account: #function,
                                 service: serviceName,
                                 accessibility: .afterFirstUnlockThisDeviceOnly,
                                 accessGroup: nil,
                                 synchronizable: true,
                                 label: "Label",
                                 description: "Description",
                                 generic: genericData,
                                 value: value)
        try item.save()
        
        XCTAssertEqual(mock.operations[0], .init(action: .delete, query: query))
        XCTAssertEqual(mock.operations[1], .init(action: .add, query: query))

        // Test failed save
        mock.reset()
        mock.expect(errSecItemNotFound)
        mock.expect(errSecAuthFailed)
        XCTAssertThrowsError(try item.save())
    }
    
    func testItemDelete() throws {
        let genericData = "This is generic data".data(using: .utf8)!
        let value = "This is value data".data(using: .utf8)!
        let query = [
            "acct": "testItemDelete()",
            "class": "genp",
            "gena": genericData,
            "pdmn": "aku",
            "nleg": 1,
            "svce": "KeychainTests.swift",
            "v_Data": value
        ] as CFDictionary
        mock.expect(noErr)

        let item = Keychain.Item(account: #function,
                                 service: serviceName,
                                 accessibility: .unlockedThisDeviceOnly,
                                 generic: genericData,
                                 value: value)
        try item.delete()
        
        XCTAssertEqual(mock.operations[0], .init(action: .delete, query: query))

        // Test failed delete
        mock.reset()
        mock.expect(errSecItemNotFound)
        XCTAssertThrowsError(try item.delete())
    }
    
    func testSearchList() throws {
        let query = [
            "acct": "testSearchList()",
            "class": "genp",
            "m_Limit": "m_LimitAll",
            "r_Attributes": 1,
            "r_Ref": 1,
            "svce": "KeychainTests.swift"
        ] as CFDictionary

        let result = [[
            "tomb": 0,
            "svce": "KeychainTests.swift",
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": "testSearchList()",
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString
        ]] as CFArray
        mock.expect(noErr, result: result)

        let search = Keychain.Search(account: #function,
                                     service: serviceName,
                                     accessGroup: nil)
        let searchResults = try search.list()
        
        XCTAssertEqual(mock.operations[0], .init(action: .copy, query: query))
        XCTAssertEqual(searchResults.first?.account, "testSearchList()")
    }
    
    func testSearchGet() throws {
        let value = "This is value data".data(using: .utf8)!

        let query = [
            "acct": "testSearchGet()",
            "class": "genp",
            "m_Limit": "m_LimitOne",
            "r_Attributes": 1,
            "r_Data": 1,
            "r_Ref": 1,
            "svce": "KeychainTests.swift"
        ] as CFDictionary

        let result = [
            "tomb": 0,
            "svce": "KeychainTests.swift",
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": "testSearchGet()",
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString,
            "v_Data": value
        ] as CFDictionary
        mock.expect(noErr, result: result)

        let search = Keychain.Search(account: #function,
                                     service: serviceName,
                                     accessGroup: nil)
        let searchResults = try search.get()
        
        XCTAssertEqual(mock.operations[0], .init(action: .copy, query: query))
        XCTAssertEqual(searchResults.account, "testSearchGet()")
        XCTAssertEqual(searchResults.value, value)
    }

    func testSearchError() throws {
        let result = [] as CFArray
        mock.expect(errSecItemNotFound, result: result)

        let search = Keychain.Search(account: #function,
                                     service: serviceName,
                                     accessGroup: nil)
        
        // Test item not found
        XCTAssertThrowsError(try search.get())

        // Test generic error
        mock.expect(errSecAuthFailed, result: result)
        XCTAssertThrowsError(try search.get())
        
        // Test invalid ref data
        mock.expect(noErr, result: result)
        XCTAssertThrowsError(try search.get())
    }
    
    func testInvalidItemData() throws {
        // Test missing account
        XCTAssertThrowsError(try Keychain.Item([:]))
        
        // Test missing value data
        XCTAssertThrowsError(try Keychain.Item([
            kSecAttrAccount as String: "TheAccountName"
        ]))

        // Test invalid accessibility option
        XCTAssertThrowsError(try Keychain.Item([
            kSecAttrAccount as String: "TheAccountName",
            kSecValueData as String: Data(),
            kSecAttrAccessible as String: "WoofWoof!"
        ]))
    }
    
    func testInvalidResultData() throws {
        // Test missing account
        XCTAssertThrowsError(try Keychain.Search.Result([:]))
        
        // Test missing creationDate
        XCTAssertThrowsError(try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date()
        ]))

        // Test missing creationDate
        XCTAssertThrowsError(try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrCreationDate as String: Date()
        ]))
    }
    
    func testListQuery() throws {
        var search: Keychain.Search
        
        search = Keychain.Search(account: #function,
                                 service: serviceName,
                                 accessGroup: nil)
        
        XCTAssertEqual(search.listQuery as NSDictionary, [
            "acct": "testListQuery()",
            "class": "genp",
            "m_Limit": "m_LimitAll",
            "r_Attributes": 1,
            "r_Ref": 1,
            "svce": "KeychainTests.swift"
        ] as NSDictionary)

        search = Keychain.Search(account: #function,
                                 service: nil,
                                 accessGroup: "my.access.group")
        
        XCTAssertEqual(search.listQuery as NSDictionary, [
            "acct": "testListQuery()",
            "agrp": "my.access.group",
            "class": "genp",
            "m_Limit": "m_LimitAll",
            "r_Attributes": 1,
            "r_Ref": 1
        ] as NSDictionary)
    }
    
    func testSearchResult() throws {
        let result = try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date(),
            kSecAttrCreationDate as String: Date()
        ])
        
        XCTAssertEqual(result.account, "TheAccountName")
    }
}

#endif
