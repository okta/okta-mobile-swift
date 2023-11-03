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

#if os(Linux)
import FoundationNetworking
#endif

@testable import TestCommon
@testable import AuthFoundation

final class UserCoordinatorTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    var coordinator: CredentialCoordinatorImpl!
    
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

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        coordinator = CredentialCoordinatorImpl(tokenStorage: storage)
        
        XCTAssertEqual(storage.allIDs.count, 0)
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: name)

        userDefaults = nil
        storage = nil
        coordinator = nil
    }
    
    func testDefaultCredentialViaToken() throws {
        try storage.add(token: token, metadata: nil, security: [])

        XCTAssertEqual(storage.allIDs.count, 1)
        
        let credential = try XCTUnwrap(coordinator.default)
        XCTAssertEqual(credential.token, token)
        
        coordinator.default = nil
        XCTAssertNil(coordinator.default)
        XCTAssertNil(storage.defaultTokenID)
        XCTAssertEqual(storage.allIDs.count, 1)
        
        XCTAssertEqual(coordinator.allIDs, [token.id])
        XCTAssertEqual(try coordinator.with(id: token.id, prompt: nil, authenticationContext: nil), credential)
    }
    
    func testImplicitCredentialForToken() throws {
        let credential = try coordinator.store(token: token, tags: [:], security: [])
        
        XCTAssertEqual(storage.allIDs, [token.id])
        XCTAssertEqual(storage.defaultTokenID, token.id)
        XCTAssertEqual(coordinator.default, credential)
    }
    
    func testNotifications() throws {
        let oldCredential = coordinator.default
        
        let recorder = NotificationRecorder(observing: [.defaultCredentialChanged])
        
        let credential = try coordinator.store(token: token, tags: [:], security: [])
        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertEqual(recorder.notifications.first?.object as? Credential, credential)
        XCTAssertNotEqual(oldCredential, credential)
        
        recorder.reset()
        coordinator.default = nil
        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertNil(recorder.notifications.first?.object)
    }
}
