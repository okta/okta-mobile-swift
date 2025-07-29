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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))

import Testing
import Foundation
@testable import AuthFoundation
@testable import TestCommon

@Suite("Keychain Tests")
struct KeychainTests {
    let serviceName = (#file as NSString).lastPathComponent
    
    @Test("Save new item", .mockKeychain)
    func testItemSave() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let genericData = "This is generic data".data(using: .utf8)!
        let value = "This is value data".data(using: .utf8)!
        let query = [
            "acct": "testItemSave()",
            "class": "genp",
            "desc": "Description",
            "gena": genericData,
            "labl": "Label",
            "pdmn": "cku",
            "r_Attributes": 1,
            "r_Data": 1,
            "r_Ref": 1,
            "nleg": 1,
            "sync": 1,
            "svce": "KeychainTests.swift",
            "v_Data": value
        ] as CFDictionary
        mock.expect(errSecItemNotFound)
        mock.expect(noErr, result: [
            "tomb": 0,
            "svce": "KeychainTests.swift",
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": "testItemSave()",
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString,
            "v_Data": value
        ] as CFDictionary)

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

        #expect(mock.operations[0] == .init(action: .delete, query: [
            "acct": "testItemSave()",
            "class": "genp",
            "sync": 1,
            "svce": "KeychainTests.swift",
        ], attributes: nil))
        #expect(mock.operations[1] == .init(action: .add, query: query, attributes: nil))

        // Test failed save
        mock.reset()
        mock.expect(errSecItemNotFound)
        mock.expect(errSecAuthFailed)
        #expect(throws: (any Error).self) {
            try item.save()
        }
    }
    
    @Test("Update an item without getting it first", .mockKeychain)
    func testItemUpdate() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let oldData = "Old value".data(using: .utf8)!
        let newData = "New value".data(using: .utf8)!
        
        let query = [
            "acct": "testItemUpdate()",
            "class": "genp",
            "svce": "KeychainTests.swift",
        ] as CFDictionary
        
        let attributes = [
            "acct": "testItemUpdate()",
            "svce": "KeychainTests.swift",
            "pdmn": "ak",
            "nleg": 1,
            "v_Data": newData
        ] as CFDictionary

        mock.expect(noErr)

        let oldItem = Keychain.Item(account: #function,
                                    service: serviceName,
                                    accessibility: .afterFirstUnlockThisDeviceOnly,
                                    value: oldData)

        let newItem = Keychain.Item(account: #function,
                                    service: serviceName,
                                    accessibility: .unlocked,
                                    value: newData)

        try oldItem.update(newItem, authenticationContext: nil)

        #expect(mock.operations[0] == .init(action: .update, query: query, attributes: attributes))
    }

    @Test("Delete item without a search", .mockKeychain)
    func testItemDelete() throws {
        let mock = try #require(Test.current?.mockKeychain)
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
        
        #expect(mock.operations[0] == .init(action: .delete, query: query, attributes: nil))

        // Test failed delete
        mock.reset()
        mock.expect(errSecItemNotFound)
        #expect(throws: (any Error).self) {
            try item.delete()
        }
    }
    
    @Test("List search results", .mockKeychain)
    func testSearchList() throws {
        let mock = try #require(Test.current?.mockKeychain)
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
        mock.expect(noErr)
        mock.expect(noErr)

        let search = Keychain.Search(account: #function,
                                     accessGroup: nil)
        let searchResults = try search.list()

        // Delete an individual search result
        try searchResults.first?.delete()

        // Delete all items matching a search
        try search.delete()

        #expect(mock.operations[0] == .init(action: .copy, query: [
            "acct": "testSearchList()",
            "class": "genp",
            "m_Limit": "m_LimitAll",
            "r_Attributes": 1,
            "r_Ref": 1,
        ], attributes: nil))
        #expect(searchResults.first?.account == "testSearchList()")

        // Check search result delete
        #expect(mock.operations[1] == .init(action: .delete, query: [
            "acct": "testSearchList()",
            "class": "genp",
            "svce": "KeychainTests.swift",
            "agrp": "com.okta.sample.app",
        ] as CFDictionary, attributes: nil))

        // Check search delete
        #expect(mock.operations[2] == .init(action: .delete, query: [
            "acct": "testSearchList()",
            "class": "genp",
        ] as CFDictionary, attributes: nil))
    }
    
    @Test("Get a single item from a search", .mockKeychain)
    func testSearchGet() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let value = "This is value data".data(using: .utf8)!

        var query: [String: Any] = [
            "acct": "testSearchGet()",
            "class": "genp",
            "m_Limit": "m_LimitOne",
            "r_Attributes": 1,
            "r_Data": 1,
            "r_Ref": 1,
            "svce": "KeychainTests.swift"
        ]

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
        let searchResults = try search.get(prompt: "UI Prompt",
                                           authenticationContext: nil)
        
        query["u_OpPrompt"] = "UI Prompt"

        #expect(mock.operations[0] == .init(action: .copy, query: query as CFDictionary, attributes: nil))
        #expect(searchResults.account == "testSearchGet()")
        #expect(searchResults.value == value)
    }

    @Test("Error while getting a search result", .mockKeychain)
    func testSearchError() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let result = [] as CFArray
        mock.expect(errSecItemNotFound, result: result)

        let search = Keychain.Search(account: #function,
                                     service: serviceName,
                                     accessGroup: nil)
        
        // Test item not found
        #expect(throws: (any Error).self) {
            try search.get()
        }

        // Test generic error
        mock.expect(errSecAuthFailed, result: result)
        #expect(throws: (any Error).self) {
            try search.get()
        }
        
        // Test invalid ref data
        mock.expect(noErr, result: result)
        #expect(throws: (any Error).self) {
            try search.get()
        }
    }
    
    @Test("Invalid item data", .mockKeychain)
    func testInvalidItemData() throws {
        // Test missing account
        #expect(throws: (any Error).self) {
            try Keychain.Item([:])
        }
        
        // Test missing value data
        #expect(throws: (any Error).self) {
            try Keychain.Item([
                kSecAttrAccount as String: "TheAccountName"
            ])
        }

        // Test invalid accessibility option
        #expect(throws: (any Error).self) {
            try Keychain.Item([
                kSecAttrAccount as String: "TheAccountName",
                kSecValueData as String: Data(),
                kSecAttrAccessible as String: "WoofWoof!"
            ])
        }
    }
    
    @Test("Invalid search result data", .mockKeychain)
    func testInvalidResultData() throws {
        // Test missing account
        #expect(throws: (any Error).self) {
            try Keychain.Search.Result([:])
        }
        
        // Test missing creationDate
        #expect(throws: (any Error).self) {
            try Keychain.Search.Result([
                kSecAttrAccount as String: "TheAccountName",
                kSecAttrModificationDate as String: Date()
            ])
        }

        // Test missing creationDate
        #expect(throws: (any Error).self) {
            try Keychain.Search.Result([
                kSecAttrAccount as String: "TheAccountName",
                kSecAttrCreationDate as String: Date()
            ])
        }
    }
    
    @Test("Test keychain search query", .mockKeychain)
    func testListQuery() throws {
        var search: Keychain.Search
        
        search = Keychain.Search(account: #function,
                                 service: serviceName,
                                 accessGroup: nil)
        
        #expect(search.listQuery as NSDictionary == [
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
        
        #expect(search.listQuery as NSDictionary == [
            "acct": "testListQuery()",
            "agrp": "my.access.group",
            "class": "genp",
            "m_Limit": "m_LimitAll",
            "r_Attributes": 1,
            "r_Ref": 1
        ] as NSDictionary)
    }
    
    @Test("Test keychain search result", .mockKeychain)
    func testSearchResult() throws {
        let result = try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date(),
            kSecAttrCreationDate as String: Date(),
            kSecAttrAccessible as String: "ak"
        ])
        
        #expect(result.account == "TheAccountName")
    }

    @Test("Test search result, and getting an item from it", .mockKeychain)
    func testSearchResultGet() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let result = try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date(),
            kSecAttrCreationDate as String: Date(),
            kSecAttrAccessible as String: "ak"
        ])
        
        mock.expect(noErr, result: [
            "tomb": 0,
            "svce": "KeychainTests.swift",
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": "TheAccountName",
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString,
            "v_Data": "TestData".data(using: .utf8)
        ] as CFDictionary)

        let item = try result.get(prompt: "Why I need this")
        #expect(mock.operations[0] == .init(action: .copy, query: [
            "acct": "TheAccountName",
            "class": "genp",
            "m_Limit": "m_LimitOne",
            "r_Attributes": 1,
            "r_Data": 1,
            "r_Ref": 1,
            "u_OpPrompt": "Why I need this"
        ] as CFDictionary, attributes: nil))
        #expect(item.account == "TheAccountName")
        #expect(item.value == "TestData".data(using: .utf8))
    }

    @Test("Delete a search result item", .mockKeychain)
    func testSearchResultDelete() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let result = try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date(),
            kSecAttrCreationDate as String: Date(),
            kSecAttrAccessible as String: "ak"
        ])
        
        mock.expect(noErr)

        try result.delete()
        #expect(mock.operations[0] == .init(action: .delete, query: [
            "acct": "TheAccountName",
            "class": "genp"
        ] as CFDictionary, attributes: nil))
    }

    @Test("Update a search result item", .mockKeychain)
    func testSearchResultUpdate() throws {
        let mock = try #require(Test.current?.mockKeychain)
        let result = try Keychain.Search.Result([
            kSecAttrAccount as String: "TheAccountName",
            kSecAttrModificationDate as String: Date(),
            kSecAttrCreationDate as String: Date(),
            kSecAttrAccessible as String: "ak"
        ])
        
        mock.expect(noErr)

        let newItem = Keychain.Item(account: "TheAccountName",
                                    accessibility: .unlocked,
                                    value: "New Value".data(using: .utf8)!)

        try result.update(newItem)
        #expect(mock.operations[0] == .init(action: .update, query: [
            "acct": "TheAccountName",
            "class": "genp"
        ] as CFDictionary, attributes: [
            "acct": "TheAccountName",
            "nleg": 1,
            "pdmn": "ak",
            "v_Data": "New Value".data(using: .utf8)!
        ] as CFDictionary))
    }
}

#endif
