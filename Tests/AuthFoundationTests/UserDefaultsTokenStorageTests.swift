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

import Testing
import Foundation
import TestCommon

@testable import AuthFoundation

#if swift(<6.0)
extension UserDefaults: @unchecked Sendable {}
#else
extension UserDefaults: @unchecked @retroactive Sendable {}
#endif

@Suite("UserDefaults Token Storage Tests")
class UserDefaultsTokenStorageTests {
    let token = try! Token(id: "TokenId",
                           issuedAt: Date(),
                           tokenType: "Bearer",
                           expiresIn: 300,
                           accessToken: "abcd123",
                           scope: "openid",
                           refreshToken: nil,
                           idToken: nil,
                           deviceSecret: nil,
                           context: Token.Context(configuration: .init(issuerURL: URL(string: "https://example.com")!,
                                                                       clientId: "clientid",
                                                                       scope: "openid"),
                                                  clientSettings: nil))
    
    let newToken = try! Token(id: "TokenId2",
                              issuedAt: Date(),
                              tokenType: "Bearer",
                              expiresIn: 300,
                              accessToken: "zxy987",
                              scope: "openid",
                              refreshToken: nil,
                              idToken: nil,
                              deviceSecret: nil,
                              context: Token.Context(configuration: .init(issuerURL: URL(string: "https://example.com")!,
                                                                          clientId: "clientid",
                                                                          scope: "openid"),
                                                     clientSettings: nil))

    let name: String
    let userDefaults: UserDefaults
    let storage: UserDefaultsTokenStorage

    init() async throws {
        name = "UserDefaultsTests.\(UUID().uuidString)"
        userDefaults = try #require(UserDefaults(suiteName: name))
        userDefaults.removePersistentDomain(forName: name)
        storage = await UserDefaultsTokenStorage(userDefaults: userDefaults)

        #expect(await storage.allIDs.count == 0)
    }
    
    deinit {
        userDefaults.removePersistentDomain(forName: name)
    }
    
    @Test("Default Token functionality")
    @CredentialActor
    func testDefaultToken() async throws {
        let storage = storage
        let token = token
        let newToken = newToken
        
        try storage.add(token: token, metadata: nil, security: [])
        #expect(storage.allIDs.count == 1)
        #expect(storage.defaultTokenID == token.id)
        
        try storage.setDefaultTokenID(nil)
        #expect(storage.defaultTokenID == nil)
        #expect(storage.allIDs.count == 1)
   
        #expect(throws: (any Error).self) {
            try storage.add(token: token, metadata: nil, security: [])
        }
        #expect(storage.allIDs.count == 1)
        
        #expect(throws: Never.self) {
            try storage.replace(token: token.id, with: newToken, security: nil)
        }
        #expect(storage.allIDs.count == 1)

        #expect(throws: Never.self) {
            try storage.remove(id: token.id)
        }
        #expect(storage.allIDs.count == 0)

        #expect(throws: Never.self) {
            try storage.remove(id: token.id)
        }
        #expect(storage.allIDs.count == 0)
    }

    @Test("Implicit Default Token functionality")
    @CredentialActor
    func implicitDefaultToken() async throws {
        let storage = storage
        let token = token
        
        #expect(storage.defaultTokenID == nil)
        
        #expect(throws: Never.self) {
            try storage.add(token: token, metadata: nil, security: [])
        }
        #expect(storage.allIDs.count == 1)

        #expect(storage.defaultTokenID == token.id)
    }

    @Test("Remove Default Token functionality")
    @CredentialActor
    func removeDefaultToken() async throws {
        let storage = storage
        let token = token
        
        try storage.add(token: token, metadata: nil, security: [])
        try storage.setDefaultTokenID(token.id)
        #expect(storage.allIDs.count == 1)

        #expect(throws: Never.self) {
            try storage.remove(id: token.id)
        }
        #expect(storage.allIDs.count == 0)
        #expect(storage.defaultTokenID == nil)
    }
}
