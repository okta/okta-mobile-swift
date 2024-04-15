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
import TestCommon

final class UserDefaultTokenStorageTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    
    let token = Token(id: "TokenId",
                      issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(configuration: .init(baseURL: URL(string: "https://example.com")!,
                                                                  clientId: "clientid",
                                                                  scopes: "openid"),
                                             clientSettings: nil))

    let newToken = Token(id: "TokenId2",
                         issuedAt: Date(),
                         tokenType: "Bearer",
                         expiresIn: 300,
                         accessToken: "zxy987",
                         scope: "openid",
                         refreshToken: nil,
                         idToken: nil,
                         deviceSecret: nil,
                         context: Token.Context(configuration: .init(baseURL: URL(string: "https://example.com")!,
                                                                     clientId: "clientid",
                                                                     scopes: "openid"),
                                                clientSettings: nil))

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        XCTAssertEqual(storage.allIDs.count, 0)
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: name)

        userDefaults = nil
        storage = nil
    }
    
    func testDefaultToken() throws {
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

    func testImplicitDefaultToken() throws {
        XCTAssertNil(storage.defaultTokenID)
        
        XCTAssertNoThrow(try storage.add(token: token, metadata: nil, security: []))
        XCTAssertEqual(storage.allIDs.count, 1)

        XCTAssertEqual(storage.defaultTokenID, token.id)
    }

    func testRemoveDefaultToken() throws {
        try storage.add(token: token, metadata: nil, security: [])
        try storage.setDefaultTokenID(token.id)
        XCTAssertEqual(storage.allIDs.count, 1)

        XCTAssertNoThrow(try storage.remove(id: token.id))
        XCTAssertEqual(storage.allIDs.count, 0)
        XCTAssertNil(storage.defaultTokenID)
    }
}
#endif
