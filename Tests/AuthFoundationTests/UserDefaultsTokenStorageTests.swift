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

import XCTest
@testable import AuthFoundation
import TestCommon

#if swift(<6.0)
extension UserDefaults: @unchecked Sendable {}
#else
extension UserDefaults: @unchecked @retroactive Sendable {}
#endif

final class UserDefaultTokenStorageTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    
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

    override func setUp() async throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)
        storage = await UserDefaultsTokenStorage(userDefaults: userDefaults)

        let tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 0)
    }
    
    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: name)

        userDefaults = nil
        storage = nil
    }

    @CredentialActor
    func testDefaultToken() async throws {
        try storage.add(token: token, metadata: nil, security: [])
        XCTAssertEqual(storage.allIDs.count, 1)
        XCTAssertEqual(storage.defaultTokenID, token.id)
        
        try storage.setDefaultTokenID(nil)
        XCTAssertNil(storage.defaultTokenID)
        XCTAssertEqual(storage.allIDs.count, 1)
   
        XCTAssertThrowsError(try storage.add(token: token, metadata: nil, security: []))
        XCTAssertEqual(storage.allIDs.count, 1)
        
        XCTAssertNoThrow(try storage.replace(token: token.id, with: newToken, security: nil))
        XCTAssertEqual(storage.allIDs.count, 1)

        XCTAssertNoThrow(try storage.remove(id: token.id))
        XCTAssertEqual(storage.allIDs.count, 0)

        XCTAssertNoThrow(try storage.remove(id: token.id))
        XCTAssertEqual(storage.allIDs.count, 0)
    }

    @CredentialActor
    func testImplicitDefaultToken() async throws {
        XCTAssertNil(storage.defaultTokenID)
        
        XCTAssertNoThrow(try storage.add(token: token, metadata: nil, security: []))
        XCTAssertEqual(storage.allIDs.count, 1)

        XCTAssertEqual(storage.defaultTokenID, token.id)
    }

    @CredentialActor
    func testRemoveDefaultToken() async throws {
        try storage.add(token: token, metadata: nil, security: [])
        try storage.setDefaultTokenID(token.id)
        XCTAssertEqual(storage.allIDs.count, 1)

        XCTAssertNoThrow(try storage.remove(id: token.id))
        XCTAssertEqual(storage.allIDs.count, 0)
        XCTAssertNil(storage.defaultTokenID)
    }
}
