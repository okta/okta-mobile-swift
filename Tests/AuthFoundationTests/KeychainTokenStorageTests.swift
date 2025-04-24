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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.9) && os(visionOS))

import XCTest
@testable import AuthFoundation
@testable import TestCommon

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
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(configuration: .init(issuerURL: URL(string: "https://example.com")!,
                                                                  clientId: "clientid",
                                                                  scope: "openid"),
                                             clientSettings: nil))

    override func setUp() async throws {
        mock = MockKeychain()
        Keychain.implementation.wrappedValue = mock
        storage = await KeychainTokenStorage()

        XCTAssertEqual(mock.operations.count, 0)
    }
    
    override func tearDownWithError() throws {
        Keychain.resetToDefault()

        mock = nil
        storage = nil
    }

    func testEmptyAllIDs() async throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)

        let tokens = await storage.allIDs
        XCTAssertEqual(tokens, [])
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

    func testAllIDs() async throws {
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

        let allIds = await storage.allIDs
        XCTAssertEqual(mock.operations.count, 2)
        XCTAssertEqual(allIds.count, 1)
        XCTAssertEqual(allIds.first, "SomeAccount1")
    }

    func testDefaultToken() async throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
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
        try await storage.add(token: token, metadata: nil, security: [.accessibility(.unlocked)])
        XCTAssertEqual(mock.operations.count, 9)
        
        // Adding the new token
        // - Searching for tokens matching the same ID
        XCTAssertEqual(mock.operations[0].action, .copy)
        XCTAssertEqual(mock.operations[0].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[0].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[0].query["m_Limit"] as? String, "m_LimitAll")

        // - Checking how many tokens are already registered
        XCTAssertEqual(mock.operations[1].action, .copy)
        XCTAssertEqual(mock.operations[1].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertNil(mock.operations[1].query["acct"] as? String)
        XCTAssertEqual(mock.operations[1].query["m_Limit"] as? String, "m_LimitAll")

        // - Preemptively deleting the newly-added token
        XCTAssertEqual(mock.operations[2].action, .delete)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[2].query["svce"] as? String, KeychainTokenStorage.serviceName)

        // - Adding the new token
        XCTAssertEqual(mock.operations[3].action, .add)
        XCTAssertEqual(mock.operations[3].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[3].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[3].query["pdmn"] as? String, Keychain.Accessibility.unlocked.rawValue)
        let tokenQuery = mock.operations[3].query

        // - Preemptively deleting the newly-added metadata
        XCTAssertEqual(mock.operations[4].action, .delete)
        XCTAssertEqual(mock.operations[4].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[4].query["svce"] as? String, KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        XCTAssertEqual(mock.operations[5].action, .add)
        XCTAssertEqual(mock.operations[5].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[5].query["svce"] as? String, KeychainTokenStorage.metadataName)
        XCTAssertEqual(mock.operations[5].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlock.rawValue)

        // - Loading the current defaultTokenID
        XCTAssertEqual(mock.operations[6].action, .copy)
        XCTAssertNil(mock.operations[6].query["svce"] as? String)
        XCTAssertEqual(mock.operations[6].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[6].query["m_Limit"] as? String, "m_LimitOne")

        // Deleting the current default key
        XCTAssertEqual(mock.operations[7].action, .delete)
        XCTAssertEqual(mock.operations[7].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        
        // Adding the new default token ID
        XCTAssertEqual(mock.operations[8].action, .add)
        XCTAssertEqual(mock.operations[8].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[8].query["v_Data"] as? Data, token.id.data(using: .utf8))
        XCTAssertEqual(mock.operations[8].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlock.rawValue)

        var defaultTokenID = await storage.defaultTokenID
        XCTAssertEqual(defaultTokenID, token.id)

        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()
        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        var tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 1)

        mock.reset()
        mock.expect(noErr)

        try await storage.setDefaultTokenID(nil)
        defaultTokenID = await storage.defaultTokenID
        XCTAssertNil(defaultTokenID)

        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 1)

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        try await XCTAssertThrowsErrorAsync(await storage.add(token: token, metadata: nil, security: []))

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 1)
    }

    func testImplicitDefaultToken() async throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        var defaultTokenID = await storage.defaultTokenID
        XCTAssertNil(defaultTokenID)

        mock.reset()
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        await XCTAssertNoThrowAsync(try await storage.add(token: token, metadata: nil, security: []))

        let tokenQuery = mock.operations[3].query
        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)

        defaultTokenID = await storage.defaultTokenID
        let tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 1)
        XCTAssertEqual(defaultTokenID, token.id)
    }

    func testRemoveDefaultToken() async throws {
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        try await storage.add(token: token, metadata: nil, security: [])

        let tokenQuery = mock.operations[3].query
        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()

        let defaultQuery = mock.operations[5].query
        var defaultResult = defaultQuery as! [String:Any?]
        defaultResult["mdat"] = Date()
        defaultResult["cdat"] = Date()

        var defaultTokenID = await storage.defaultTokenID
        XCTAssertEqual(defaultTokenID, token.id)

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)

        var tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 1)

        mock.reset()

        mock.expect(noErr, result: tokenResult as CFDictionary)
        mock.expect(noErr)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr, result: defaultResult as CFDictionary)
        mock.expect(noErr)
        mock.expect(noErr, result: tokenResult as CFDictionary)
        mock.expect(noErr)

        await XCTAssertNoThrowAsync(try await storage.remove(id: token.id))
        defaultTokenID = await storage.defaultTokenID
        tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 0)
        XCTAssertNil(defaultTokenID)
    }
    
    func testSetMetadata() async throws {
        mock.expect(errSecSuccess, result: [dummyGetResult] as CFArray)
        mock.expect(noErr)
        
        let metadata = Token.Metadata(token: token, tags: ["foo": "bar"])
        try await storage.setMetadata(metadata)

        let updateOperation = try XCTUnwrap(mock.operations[1])
        XCTAssertEqual(updateOperation.action, .update)
        XCTAssertEqual(updateOperation.attributes?["pdmn"] as? String, "ak")
        
        let data = try XCTUnwrap(updateOperation.attributes?["v_Data"] as? Data)
        let compareMetadata = try Token.Metadata.jsonDecoder.decode(Token.Metadata.self, from: data)
        XCTAssertEqual(metadata.tags, compareMetadata.tags)
    }

    func testReplaceTokenSecurity() async throws {
        mock.expect(errSecSuccess, result: [dummyGetResult] as CFArray)
        mock.expect(noErr)
        
        try await storage.replace(token: token.id,
                                  with: token,
                                  security: [
                                    .accessibility(.whenPasswordSetThisDeviceOnly),
                                    .accessGroup("otherGroup")
                                  ])

        let updateOperation = try XCTUnwrap(mock.operations[1])
        XCTAssertEqual(updateOperation.action, .update)
        XCTAssertEqual(updateOperation.attributes?["pdmn"] as? String, "akpu")
        XCTAssertEqual(updateOperation.attributes?["agrp"] as? String, "otherGroup")
    }
    
    func testAddTokenWithSecurity() async throws {
        // - Find duplicate items
        mock.expect(errSecSuccess, result: [] as CFArray)

        // - Determine if we're implicitly changing the default
        mock.expect(errSecSuccess, result: [] as CFArray)

        // - Save the item
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        // Compare existing defaultTokenID
        mock.expect(errSecSuccess, result: [] as CFArray)
        
        // Save new defaultTokenID
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        
        Credential.Security.isDefaultSynchronizable = false
        try await storage.add(token: token,
                              metadata: Token.Metadata(token: token,
                                                       tags: ["tag": "value"]),
                              security: [.accessibility(.unlockedThisDeviceOnly),
                                         .accessGroup("com.example.myapp")])

        XCTAssertEqual(mock.operations.count, 9)

        // - Preemptively deleting the newly-added token
        XCTAssertEqual(mock.operations[2].action, .delete)
        XCTAssertEqual(mock.operations[2].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[2].query["svce"] as? String, KeychainTokenStorage.serviceName)

        // - Adding the new token
        XCTAssertEqual(mock.operations[3].action, .add)
        XCTAssertEqual(mock.operations[3].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[3].query["svce"] as? String, KeychainTokenStorage.serviceName)
        XCTAssertEqual(mock.operations[3].query["pdmn"] as? String, Keychain.Accessibility.unlockedThisDeviceOnly.rawValue)

        // - Preemptively deleting the newly-added metadata
        XCTAssertEqual(mock.operations[4].action, .delete)
        XCTAssertEqual(mock.operations[4].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[4].query["svce"] as? String, KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        XCTAssertEqual(mock.operations[5].action, .add)
        XCTAssertEqual(mock.operations[5].query["acct"] as? String, token.id)
        XCTAssertEqual(mock.operations[5].query["svce"] as? String, KeychainTokenStorage.metadataName)
        XCTAssertEqual(mock.operations[5].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlockThisDeviceOnly.rawValue)

        // Adding the new default token ID
        XCTAssertEqual(mock.operations[8].action, .add)
        XCTAssertEqual(mock.operations[8].query["acct"] as? String, KeychainTokenStorage.defaultTokenName)
        XCTAssertEqual(mock.operations[8].query["v_Data"] as? Data, token.id.data(using: .utf8))
        XCTAssertEqual(mock.operations[5].query["pdmn"] as? String, Keychain.Accessibility.afterFirstUnlockThisDeviceOnly.rawValue)

        let defaultTokenID = await storage.defaultTokenID
        XCTAssertEqual(defaultTokenID, token.id)
    }
}

#endif
