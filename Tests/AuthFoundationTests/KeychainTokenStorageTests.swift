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

@Suite("Keychain Token Storage Tests")
struct KeychainTokenStorageTests {
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

    @Test("Empty allIDs when no tokens exist", .mockKeychain)
    func testEmptyAllIDs() async throws {
        let mock = try #require(Test.current?.mockKeychain)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)
        let storage = await KeychainTokenStorage()

        let tokens = await storage.allIDs
        #expect(tokens == [])
        #expect(mock.operations.count == 2)

        // - Listing the token items
        #expect(mock.operations[0].action == .copy)
        #expect(mock.operations[0].query["svce"] as? String == KeychainTokenStorage.serviceName)
        #expect(mock.operations[0].query["class"] as? String == "genp")
        #expect(mock.operations[0].query["m_Limit"] as? String == "m_LimitAll")

        // - Listing the token metadata
        #expect(mock.operations[1].action == .copy)
        #expect(mock.operations[1].query["svce"] as? String == KeychainTokenStorage.metadataName)
        #expect(mock.operations[1].query["class"] as? String == "genp")
        #expect(mock.operations[1].query["m_Limit"] as? String == "m_LimitAll")
    }

    @Test("Successful allIDs when tokens exist", .mockKeychain)
    func testAllIDs() async throws {
        let mock = try #require(Test.current?.mockKeychain)
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

        let storage = await KeychainTokenStorage()
        let allIds = await storage.allIDs
        #expect(mock.operations.count == 2)
        #expect(allIds.count == 1)
        #expect(allIds.first == "SomeAccount1")
    }

    @Test("`default` token results", .mockKeychain)
    func testDefaultToken() async throws {
        let mock = try #require(Test.current?.mockKeychain)
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
        
        let storage = await KeychainTokenStorage()
        Credential.Security.isDefaultSynchronizable = true
        try await storage.add(token: token, metadata: nil, security: [.accessibility(.unlocked)])
        #expect(mock.operations.count == 9)
        
        // Adding the new token
        // - Searching for tokens matching the same ID
        #expect(mock.operations[0].action == .copy)
        #expect(mock.operations[0].query["svce"] as? String == KeychainTokenStorage.serviceName)
        #expect(mock.operations[0].query["acct"] as? String == token.id)
        #expect(mock.operations[0].query["m_Limit"] as? String == "m_LimitAll")

        // - Checking how many tokens are already registered
        #expect(mock.operations[1].action == .copy)
        #expect(mock.operations[1].query["svce"] as? String == KeychainTokenStorage.serviceName)
        #expect(mock.operations[1].query["acct"] as? String == nil)
        #expect(mock.operations[1].query["m_Limit"] as? String == "m_LimitAll")

        // - Preemptively deleting the newly-added token
        #expect(mock.operations[2].action == .delete)
        #expect(mock.operations[2].query["acct"] as? String == token.id)
        #expect(mock.operations[2].query["svce"] as? String == KeychainTokenStorage.serviceName)

        // - Adding the new token
        #expect(mock.operations[3].action == .add)
        #expect(mock.operations[3].query["acct"] as? String == token.id)
        #expect(mock.operations[3].query["svce"] as? String == KeychainTokenStorage.serviceName)
        #expect(mock.operations[3].query["pdmn"] as? String == Keychain.Accessibility.unlocked.rawValue)
        let tokenQuery = mock.operations[3].query

        // - Preemptively deleting the newly-added metadata
        #expect(mock.operations[4].action == .delete)
        #expect(mock.operations[4].query["acct"] as? String == token.id)
        #expect(mock.operations[4].query["svce"] as? String == KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        #expect(mock.operations[5].action == .add)
        #expect(mock.operations[5].query["acct"] as? String == token.id)
        #expect(mock.operations[5].query["svce"] as? String == KeychainTokenStorage.metadataName)
        #expect(mock.operations[5].query["pdmn"] as? String == Keychain.Accessibility.afterFirstUnlock.rawValue)

        // - Loading the current defaultTokenID
        #expect(mock.operations[6].action == .copy)
        #expect(mock.operations[6].query["svce"] as? String == nil)
        #expect(mock.operations[6].query["acct"] as? String == KeychainTokenStorage.defaultTokenName)
        #expect(mock.operations[6].query["m_Limit"] as? String == "m_LimitOne")

        // Deleting the current default key
        #expect(mock.operations[7].action == .delete)
        #expect(mock.operations[7].query["acct"] as? String == KeychainTokenStorage.defaultTokenName)
        
        // Adding the new default token ID
        #expect(mock.operations[8].action == .add)
        #expect(mock.operations[8].query["acct"] as? String == KeychainTokenStorage.defaultTokenName)
        #expect(mock.operations[8].query["v_Data"] as? Data == token.id.data(using: .utf8))
        #expect(mock.operations[8].query["pdmn"] as? String == Keychain.Accessibility.afterFirstUnlock.rawValue)

        var defaultTokenID = await storage.defaultTokenID
        #expect(defaultTokenID == token.id)

        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()
        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        var tokenCount = await storage.allIDs.count
        #expect(tokenCount == 1)

        mock.reset()
        mock.expect(noErr)

        try await storage.setDefaultTokenID(nil)
        defaultTokenID = await storage.defaultTokenID
        #expect(defaultTokenID == nil)

        mock.reset()
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        tokenCount = await storage.allIDs.count
        #expect(tokenCount == 1)

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        await #expect(throws: (any Error).self) {
            try await storage.add(token: token, metadata: nil, security: [])
        }

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        tokenCount = await storage.allIDs.count
        #expect(tokenCount == 1)
    }

    @Test("Implicit `default` assignment", .mockKeychain)
    func testImplicitDefaultToken() async throws {
        let mock = try #require(Test.current?.mockKeychain)
        mock.expect(errSecSuccess, result: [] as CFArray)
        let storage = await KeychainTokenStorage()
        var defaultTokenID = await storage.defaultTokenID
        #expect(defaultTokenID == nil)

        mock.reset()
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        do {
            try await storage.add(token: token, metadata: nil, security: [])
        } catch {
            #expect(Bool(false), "Expected no error but got \(error)")
        }

        let tokenQuery = mock.operations[3].query
        var tokenResult = tokenQuery as! [String:Any?]
        tokenResult["mdat"] = Date()
        tokenResult["cdat"] = Date()

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)

        defaultTokenID = await storage.defaultTokenID
        let tokenCount = await storage.allIDs.count
        #expect(tokenCount == 1)
        #expect(defaultTokenID == token.id)
    }

    @Test("Unassign `default` token when it is removed", .mockKeychain)
    func testRemoveDefaultToken() async throws {
        let mock = try #require(Test.current?.mockKeychain)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr)
        mock.expect(noErr, result: dummyGetResult)

        let storage = await KeychainTokenStorage()
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
        #expect(defaultTokenID == token.id)

        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)
        mock.expect(noErr, result: NSArray(arrayLiteral: tokenResult as CFDictionary) as CFArray)

        var tokenCount = await storage.allIDs.count
        #expect(tokenCount == 1)

        mock.reset()

        mock.expect(noErr, result: tokenResult as CFDictionary)
        mock.expect(noErr)
        mock.expect(errSecSuccess, result: [] as CFArray)
        mock.expect(noErr, result: defaultResult as CFDictionary)
        mock.expect(noErr)
        mock.expect(noErr, result: tokenResult as CFDictionary)
        mock.expect(noErr)

        do {
            try await storage.remove(id: token.id)
        } catch {
            #expect(Bool(false), "Expected no error but got \(error)")
        }
        defaultTokenID = await storage.defaultTokenID
        tokenCount = await storage.allIDs.count
        #expect(tokenCount == 0)
        #expect(defaultTokenID == nil)
    }
    
    @Test("Explicitly set token metadata", .mockKeychain)
    func testSetMetadata() async throws {
        let mock = try #require(Test.current?.mockKeychain)
        mock.expect(errSecSuccess, result: [dummyGetResult] as CFArray)
        mock.expect(noErr)
        
        let storage = await KeychainTokenStorage()
        let metadata = Token.Metadata(token: token, tags: ["foo": "bar"])
        try await storage.setMetadata(metadata)

        let updateOperation = mock.operations[1]
        #expect(updateOperation.action == .update)
        #expect(updateOperation.attributes?["pdmn"] as? String == "ak")
        
        let data = updateOperation.attributes?["v_Data"] as? Data
        #expect(data != nil)
        if let data = data {
            let compareMetadata = try Token.Metadata.jsonDecoder.decode(Token.Metadata.self, from: data)
            #expect(metadata.tags == compareMetadata.tags)
        }
    }

    @Test("Replace existing token with security options", .mockKeychain)
    func testReplaceTokenSecurity() async throws {
        let mock = try #require(Test.current?.mockKeychain)
        mock.expect(errSecSuccess, result: [dummyGetResult] as CFArray)
        mock.expect(noErr)
        
        let storage = await KeychainTokenStorage()
        try await storage.replace(token: token.id,
                                  with: token,
                                  security: [
                                    .accessibility(.whenPasswordSetThisDeviceOnly),
                                    .accessGroup("otherGroup")
                                  ])

        let updateOperation = mock.operations[1]
        #expect(updateOperation.action == .update)
        #expect(updateOperation.attributes?["pdmn"] as? String == "akpu")
        #expect(updateOperation.attributes?["agrp"] as? String == "otherGroup")
    }
    
    @Test("Add new token with security options", .mockKeychain)
    func testAddTokenWithSecurity() async throws {
        let mock = try #require(Test.current?.mockKeychain)

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

        let storage = await KeychainTokenStorage()
        try await storage.add(token: token,
                              metadata: Token.Metadata(token: token,
                                                       tags: ["tag": "value"]),
                              security: [.accessibility(.unlockedThisDeviceOnly),
                                         .accessGroup("com.example.myapp")])

        #expect(mock.operations.count == 9)

        // - Preemptively deleting the newly-added token
        #expect(mock.operations[2].action == .delete)
        #expect(mock.operations[2].query["acct"] as? String == token.id)
        #expect(mock.operations[2].query["svce"] as? String == KeychainTokenStorage.serviceName)

        // - Adding the new token
        #expect(mock.operations[3].action == .add)
        #expect(mock.operations[3].query["acct"] as? String == token.id)
        #expect(mock.operations[3].query["svce"] as? String == KeychainTokenStorage.serviceName)
        #expect(mock.operations[3].query["pdmn"] as? String == Keychain.Accessibility.unlockedThisDeviceOnly.rawValue)

        // - Preemptively deleting the newly-added metadata
        #expect(mock.operations[4].action == .delete)
        #expect(mock.operations[4].query["acct"] as? String == token.id)
        #expect(mock.operations[4].query["svce"] as? String == KeychainTokenStorage.metadataName)

        // - Adding the new metadata
        #expect(mock.operations[5].action == .add)
        #expect(mock.operations[5].query["acct"] as? String == token.id)
        #expect(mock.operations[5].query["svce"] as? String == KeychainTokenStorage.metadataName)
        #expect(mock.operations[5].query["pdmn"] as? String == Keychain.Accessibility.afterFirstUnlockThisDeviceOnly.rawValue)

        // Adding the new default token ID
        #expect(mock.operations[8].action == .add)
        #expect(mock.operations[8].query["acct"] as? String == KeychainTokenStorage.defaultTokenName)
        #expect(mock.operations[8].query["v_Data"] as? Data == token.id.data(using: .utf8))
        #expect(mock.operations[5].query["pdmn"] as? String == Keychain.Accessibility.afterFirstUnlockThisDeviceOnly.rawValue)

        let defaultTokenID = await storage.defaultTokenID
        #expect(defaultTokenID == token.id)
    }
}

#endif
