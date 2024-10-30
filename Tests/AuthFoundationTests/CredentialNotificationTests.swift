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

final class CredentialNotificationTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    var coordinator: CredentialCoordinatorImpl!
    var notificationCenter: NotificationCenter!
    
    let token = try! Token(id: "TokenId",
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

        notificationCenter = NotificationCenter()
        storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        coordinator = CredentialCoordinatorImpl(tokenStorage: storage, notificationCenter: notificationCenter)
        
        XCTAssertEqual(storage.allIDs.count, 0)
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: name)

        userDefaults = nil
        storage = nil
        coordinator = nil
    }
        
    func testNotifications() throws {
        let oldCredential = coordinator.default
        
        let recorder = NotificationRecorder(notificationCenter: notificationCenter,
                                            observing: [.defaultCredentialChanged])
        
        let credential = try coordinator.store(token: token, security: [])
        sleep(for: .short)
        
        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertEqual(recorder.notifications.first?.object as? Credential, credential)
        XCTAssertNotEqual(oldCredential, credential)
        
        recorder.reset()
        coordinator.default = nil
        sleep(for: .short)

        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertNil(recorder.notifications.first?.object)
    }
}
