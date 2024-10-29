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

#if canImport(Darwin)

import XCTest
@testable import AuthFoundation
@testable import TestCommon
@testable import Keychain
@testable import KeychainTestCommon

final class KeychainTokenStorageTests: XCTestCase {
    var mock: MockKeychain!
    var storage: KeychainTokenStorage!
    let dummyGetResult: CFDictionary = [
        "tomb": 0,
        "svce": "ServiceNme",
        "musr": nil,
        "class": "genp",
        "sync": 0,
        "cdat": Date(),
        "mdat": Date(),
        "pdmn": "ak",
        "agrp": "com.okta.sample.app",
        "acct": "SomeAccountID",
        "sha": "someshadata".data(using: .utf8),
        "UUID": UUID().uuidString,
        "v_Data": Data()
    ] as CFDictionary
    
    let token = try! Token(id: "TokenId",
                      issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken:  "eyJraWQiOiJrNkhOMkRLb2sta0V4akpHQkxxZ3pCeU1Dbk4xUnZ6RU9BLTF1a1RqZXhBIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFUNTZqYXNkZmxNY1p5TnkxVmk2cnprTEIwbHEyYzBsSHFFSjhwSGN0NHV6aWxhazAub2FyOWVhenlMakFtNm13Wkc0dzQiLCJpc3MiOiJodHRhczovL2V4YW1wbGUub2t0YS5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiJhcGk6Ly9kZWZhdWx0IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImNpZCI6IjBvYTNlbjRmSTVhM2RkYzIwNHc1IiwidWlkIjoiMDB1MnE1UTRhY1ZPWG9TYzA0dzUiLCJzY3AiOlsib2ZmbGluZV9hY2Nlc3MiLCJwcm9maWxlIiwib3BlbmlkIl0sInN1YiI6InNhbXBsZS51c2VyQG9rdGEuY29tIn0.MmpfvhZ8-abO9H74cetD3jj-RCptYGqeVAAs5UH9jrQWSub3X6a4ewqXXPNvgtAeuJBJSpXPIiG9cz4aDWbBmcddQQQzpqjw-BxGdRMnu4fPPJ9kbGJXSHZls7fDFHWBX71D_JTyrSzm_psoI9nQURTre-PyQvWiZIgbJE2WIqKiRECAg-VN85bU57iM3863LD97jpY6-i2ekApQLNOAjScomJTzk8NRH0SoFh17gbV-RQL_T5cIYOtQIlua79k9_F1i_36q5wfqB_tvZwpRua1xIN3zeOwVupfGPz7k-2iQvnMVoN9gOa8mLlFnK_89zJlisLhQBM4BuW1cY2EplA",
                      scope: "openid",
                      refreshToken: "theRefreshToken",
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(configuration: .init(baseURL: URL(string: "https://example.com")!,
                                                                  clientId: "clientid",
                                                                  scopes: "openid"),
                                             clientSettings: nil))

    func keychainQuery(service: String?, account: String?, group: String? = nil, sync: Bool? = nil, accessibility: Keychain.Accessibility = .afterFirstUnlock, data: Data? = nil) -> CFDictionary {
        var result = [
            "tomb": 0,
            "musr": NSNull(),
            "class": "genp",
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": accessibility.rawValue,
            "sha": "someshadata".data(using: .utf8)!,
            "UUID": UUID().uuidString,
        ] as [String: Any]
        
        if let service = service {
            result["svce"] = service
        }
        
        if let account = account {
            result["acct"] = account
        }
        
        if let group = group {
            result["agrp"] = group
        }
        
        if let sync = sync {
            result["sync"] = sync ? 1 : 0
        }
        
        if let data = data {
            result["v_Data"] = data
        }
        
        return result as CFDictionary
    }
    
    override func setUpWithError() throws {
        mock = MockKeychain()
        Keychain.implementation = mock

        storage = KeychainTokenStorage()
        XCTAssertEqual(mock.operations.count, 0)
    }
    
    override func tearDownWithError() throws {
        Keychain.implementation = KeychainImpl()
        
        mock = nil
        storage = nil
    }

    func testEmptyAllIDs() throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)

        XCTAssertEqual(storage.allIDs, [])
        XCTAssertEqual(mock.operations.count, 2)

        // - Listing the token items
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertEqual(mock.operations[0].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[0].query["class"] as? String, "genp")
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitAll")

        // - Listing the token metadata
        XCTAssertEqual(mock.operations[1].action, .copy)
        XCTAssertEqual(mock.operations[1].query["svce"] as? String, KeychainTokenStorage.metadataName)
        XCTAssertEqual(mock.operations[1].query["class"] as? String, "genp")
        XCTAssertEqual(mock.operations[1].query["m_Limit"] as? String, "m_LimitAll")
    }

    func testAllIDs() throws {
        func listItem(id: String, service: String) -> CFDictionary {
            [
                "tomb": 0,
                "svce": service,
                "musr": nil,
                "class": "genp",
                "sync": 0,
                "cdat": Date(),
                "mdat": Date(),
                "pdmn": "ak",
                "agrp": "com.okta.sample.app",
                "acct": "SomeAccount\(id)",
                "sha": "someshadata".data(using: .utf8),
                "UUID": UUID().uuidString
            ] as CFDictionary
        }
        mock.expect(errSecSuccess, result: [
            listItem(id: "1", service: KeychainTokenStorage.serviceName),
            listItem(id: "2", service: KeychainTokenStorage.metadataName),
        ] as CFArray)
        mock.expect(errSecSuccess, result: [
            listItem(id: "1", service: KeychainTokenStorage.serviceName)
        ] as CFArray)

        let allIds = storage.allIDs
        XCTAssertEqual(mock.operations.count, 2)
        XCTAssertEqual(allIds.count, 1)
        XCTAssertEqual(allIds.first, "SomeAccount1")
    }

    func testAddToken() throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        // Compare existing defaultTokenID
        mock.expect(errSecSuccess, result: [] as CFArray)
        
        // Save new defaultTokenID
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        
        Credential.Security.isDefaultSynchronizable = true
        try storage.add(token: token, security: [.accessibility(.unlocked)])
        XCTAssertEqual(mock.operations.count, 5)
        
        // Adding the new token
        // - Searching for tokens matching the same ID
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertEqual(mock.operations[0].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitAll")

        // - Preemptively deleting the newly-added token
        XCTAssertEqual(mock.operations[1].action, .delete)
        XCTAssertEqual(mock.operations[1].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[1].query["svce"] as? String, KeychainTokenStorage.serviceName)

        // - Adding the new token
        XCTAssertEqual(mock.operations[2].action, .add)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[2].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[2].query["pdmn"] as? String, Keychain.Accessibility.unlocked.rawValue)
        let tokenQuery = mock.operations[2].query

        // - Preemptively deleting the newly-added metadata
        XCTAssertEqual(mock.operations[3].action, .delete)
        XCTAssertEqual(mock.operations[3].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[3].query["svce"] as? String, KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        XCTAssertEqual(mock.operations[4].action, .add)
        XCTAssertEqual(mock.operations[4].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[4].query["svce"] as? String, KeychainTokenStorage.metadataName)
        XCTAssertEqual(mock.operations[4].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlock.rawValue)

        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()
        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        XCTAssertEqual(storage.allIDs.count, 1)

        mock.reset()
        mock.expect(noErr)

        try storage.setDefaultTokenID(nil)
        XCTAssertNil(storage.defaultTokenID)

        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        XCTAssertEqual(storage.allIDs.count, 1)

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        XCTAssertThrowsError(try storage.add(token: token, security: []))

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        XCTAssertEqual(storage.allIDs.count, 1)
    }
    
    func testGetDefaultTokenId() throws {
        mock.expect(errSecSuccess, result:
            keychainQuery(service: nil,
                           account: KeychainTokenStorage.defaultTokenName,
                           accessibility: .afterFirstUnlockThisDeviceOnly,
                           data: "abcd123".data(using: .utf8)))
        
        XCTAssertEqual(storage.defaultTokenID, "abcd123")

        XCTAssertEqual(mock.operations.count, 1)
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertNil(mock.operations[0].query["svce"] as? String)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitOne")
    }
    
    func testSetNilDefaultTokenId() throws {
        storage._defaultTokenID = "abcd123"
        XCTAssertEqual(storage.defaultTokenID, "abcd123")

        mock.expect(noErr)
        XCTAssertNoThrow(try storage.setDefaultTokenID(nil))
        
        XCTAssertEqual(mock.operations.count, 1)

        // Deleting the current default key
        XCTAssertEqual(mock.operations[0].action, .delete)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        
        XCTAssertNil(storage.defaultTokenID)
    }
    
    func testSetDefaultTokenIdFromNil() throws {
        // Compare existing defaultTokenID
        mock.expect(errSecSuccess, result: [] as CFArray)
        
        // Save new defaultTokenID
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        
        Credential.Security.isDefaultSynchronizable = true
        try? storage.setDefaultTokenID("abcd123")
        XCTAssertEqual(mock.operations.count, 3)
        
        // - Loading the current defaultTokenID
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertNil(mock.operations[0].query["svce"] as? String)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitOne")
        
        // Deleting the current default key
        XCTAssertEqual(mock.operations[1].action, .delete)
        XCTAssertEqual(mock.operations[1].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        
        // Adding the new default token ID
        XCTAssertEqual(mock.operations[2].action, .add)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[2].query["v_Data"] as? Data, "abcd123".data(using: .utf8))
        XCTAssertEqual(mock.operations[2].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlock.rawValue)

        XCTAssertEqual(storage._defaultTokenID, "abcd123")
    }
    
    func testSetDefaultTokenIdFromOtherValue() throws {
        // Compare existing defaultTokenID
        mock.expect(errSecSuccess, result:
            keychainQuery(service: nil,
                           account: KeychainTokenStorage.defaultTokenName,
                           accessibility: .afterFirstUnlockThisDeviceOnly,
                           data: "oldtokenid".data(using: .utf8)))

        // Save new defaultTokenID
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        
        Credential.Security.isDefaultSynchronizable = true
        try? storage.setDefaultTokenID("abcd123")
        XCTAssertEqual(mock.operations.count, 3)
        
        // - Loading the current defaultTokenID
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertNil(mock.operations[0].query["svce"] as? String)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitOne")

        // Deleting the current default key
        XCTAssertEqual(mock.operations[1].action, .delete)
        XCTAssertEqual(mock.operations[1].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)

        // Adding the new default token ID
        XCTAssertEqual(mock.operations[2].action, .add)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[2].query["v_Data"] as? Data, "abcd123".data(using: .utf8))
        XCTAssertEqual(mock.operations[2].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlock.rawValue)

        XCTAssertEqual(storage._defaultTokenID, "abcd123")
    }

    func testSetDefaultTokenIdAsDuplicate() throws {
        // Compare existing defaultTokenID
        mock.expect(errSecSuccess, result:
            keychainQuery(service: nil,
                           account: KeychainTokenStorage.defaultTokenName,
                           accessibility: .afterFirstUnlockThisDeviceOnly,
                           data: "abcd123".data(using: .utf8)))
        
        Credential.Security.isDefaultSynchronizable = true
        try? storage.setDefaultTokenID("abcd123")
        XCTAssertEqual(mock.operations.count, 1)
        
        // - Loading the current defaultTokenID
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertNil(mock.operations[0].query["svce"] as? String)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitOne")

        XCTAssertEqual(storage._defaultTokenID, "abcd123")
    }

    func testRemoveToken() throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        let newToken = try token.with(tags: ["tag": "value"])
        XCTAssertNoThrow(try storage.add(token: newToken, security: [.accessibility(.unlockedThisDeviceOnly)]))
        
        XCTAssertEqual(mock.operations.count, 5)
        
        // - Listing the preceding tokens
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[0].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitAll")
        XCTAssertEqual(mock.operations[0].query["r_Attributes"] as? Int, 1)
        XCTAssertNil(mock.operations[0].query["r_Data"])

        // - Deleting the previous token
        XCTAssertEqual(mock.operations[1].action, .delete)
        XCTAssertEqual(mock.operations[1].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[1].query["svce"] as? String, KeychainTokenStorage.serviceName)
        
        // - Adding the new token
        XCTAssertEqual(mock.operations[2].action, .add)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[2].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[2].query["pdmn"] as? String, Keychain.Accessibility.unlockedThisDeviceOnly.rawValue)

        // - Preemptively deleting the newly-added metadata
        XCTAssertEqual(mock.operations[3].action, .delete)
        XCTAssertEqual(mock.operations[3].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[3].query["svce"] as? String, KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        XCTAssertEqual(mock.operations[4].action, .add)
        XCTAssertEqual(mock.operations[4].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[4].query["svce"] as? String, KeychainTokenStorage.metadataName)
        XCTAssertEqual(mock.operations[4].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlockThisDeviceOnly.rawValue)

        let decoder = JSONDecoder()
        let tokenData = try XCTUnwrap(mock.operations[1].query["v_Data"] as? Data)
        let savedToken = try decoder.decode(Token.self, from: tokenData)
        XCTAssertEqual(savedToken, newToken)
        
        let metadataData = try XCTUnwrap(mock.operations[4].query["v_Data"] as? Data)
        let metadata = Token.Metadata(token: newToken)
        let savedMetadata = try decoder.decode(Token.Metadata.self, from: metadataData)
        XCTAssertEqual(savedMetadata, metadata)
    }
    
//    func testSetMetadata() throws {
//        mock.expect(errSecSuccess, result: [dummyGetResult] as CFArray)
//        mock.expect(noErr)
//        
//        let metadata = Token.Metadata(token: token, tags: ["foo": "bar"])
//        try storage.setMetadata(metadata)
//
//        let updateOperation = try XCTUnwrap(mock.operations[1])
//        XCTAssertEqual(updateOperation.action, .update)
//        XCTAssertEqual(updateOperation.attributes?["pdmn"] as? String, "ak")
//        
//        let data = try XCTUnwrap(updateOperation.attributes?["v_Data"] as? Data)
//        let compareMetadata = try Token.Metadata.jsonDecoder.decode(Token.Metadata.self, from: data)
//        XCTAssertEqual(metadata.tags, compareMetadata.tags)
//    }

    func testReplaceTokenSecurity() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let oldToken = try Token(id: token.id,
                                 issuedAt: token.issuedAt!.addingTimeInterval(-500),
                                 tokenType: token.tokenType,
                                 expiresIn: token.expiresIn,
                                 accessToken: token.accessToken,
                                 scope: token.scope,
                                 refreshToken: "theOldRefreshToken",
                                 idToken: nil,
                                 deviceSecret: nil,
                                 context: token.context)
        let oldMetadata = Token.Metadata(token: oldToken)
        let newMetadata = Token.Metadata(token: token)

        mock.expect(errSecSuccess, result: [
            keychainQuery(service: KeychainTokenStorage.serviceName,
                          account: token.id,
                          accessibility: .whenPasswordSetThisDeviceOnly,
                          data: try encoder.encode(oldToken))
        ] as CFArray)
        
        mock.expect(errSecSuccess, result: [
            keychainQuery(service: KeychainTokenStorage.metadataName,
                          account: token.id,
                          accessibility: .afterFirstUnlockThisDeviceOnly,
                          data: try encoder.encode(oldMetadata))
        ] as CFArray)
        
        mock.expect(noErr, result: keychainQuery(service: nil,
                                                 account: KeychainTokenStorage.defaultTokenName,
                                                 accessibility: .whenPasswordSetThisDeviceOnly,
                                                 data: try encoder.encode(token)))

        mock.expect(noErr, result: keychainQuery(service: nil,
                                                 account: KeychainTokenStorage.metadataName,
                                                 accessibility: .afterFirstUnlockThisDeviceOnly,
                                                 data: try encoder.encode(newMetadata)))
        
        try storage.update(token: token,
                           security: [
                            .accessibility(.whenPasswordSetThisDeviceOnly),
                            .accessGroup("otherGroup")
                           ])

        XCTAssertEqual(mock.operations.count, 4)
        
        let updateTokenOperation = try XCTUnwrap(mock.operations[2])
        XCTAssertEqual(updateTokenOperation.action, .update)
        XCTAssertEqual(updateTokenOperation.attributes?["pdmn"] as? String, "akpu")
        XCTAssertEqual(updateTokenOperation.attributes?["agrp"] as? String, "otherGroup")
        
        let updateMetadataOperation = try XCTUnwrap(mock.operations[3])
        XCTAssertEqual(updateMetadataOperation.action, .update)
        XCTAssertEqual(updateMetadataOperation.attributes?["pdmn"] as? String, "cku")
        XCTAssertEqual(updateMetadataOperation.attributes?["agrp"] as? String, "otherGroup")
    }
}

#endif
