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

final class DefaultTokenStorageTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: DefaultTokenStorage!
    
    let token = Token(issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(baseURL: URL(string: "https://example.com")!,
                                             refreshSettings: nil))

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        storage = DefaultTokenStorage(userDefaults: userDefaults)
        XCTAssertEqual(storage.allTokens.count, 0)
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: #file)
    }
    
    func testDefaultToken() throws {
        storage.defaultToken = token
        
        XCTAssertEqual(storage.defaultToken, token)
        XCTAssertEqual(storage.allTokens.count, 1)
        
        storage.defaultToken = nil
        XCTAssertNil(storage.defaultToken)
        XCTAssertEqual(storage.allTokens.count, 1)
   
        XCTAssertNoThrow(try storage.add(token: token))
        XCTAssertEqual(storage.allTokens.count, 1)

        XCTAssertNoThrow(try storage.remove(token: token))
        XCTAssertEqual(storage.allTokens.count, 0)

        XCTAssertNoThrow(try storage.remove(token: token))
        XCTAssertEqual(storage.allTokens.count, 0)
    }

    func testImplicitDefaultToken() throws {
        XCTAssertNil(storage.defaultToken)
        
        XCTAssertNoThrow(try storage.add(token: token))
        XCTAssertEqual(storage.allTokens.count, 1)

        XCTAssertEqual(storage.defaultToken, token)
    }

    func testRemoveDefaultToken() throws {
        storage.defaultToken = token
        XCTAssertEqual(storage.defaultToken, token)
        XCTAssertEqual(storage.allTokens.count, 1)

        XCTAssertNoThrow(try storage.remove(token: token))
        XCTAssertEqual(storage.allTokens.count, 0)
        XCTAssertNil(storage.defaultToken)
    }
}
