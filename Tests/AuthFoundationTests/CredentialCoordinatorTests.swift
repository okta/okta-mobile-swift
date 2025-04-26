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
    
    override func tearDown() async throws {
        await CredentialActor.run {
            Credential.resetToDefault()
        }
    }

    @CredentialActor
    final class TestContext {
        let name: String
        let userDefaults: UserDefaults
        let storage: UserDefaultsTokenStorage

        init(named storageName: String) {
            name = storageName
            userDefaults = UserDefaults(suiteName: storageName)!
            storage = UserDefaultsTokenStorage(userDefaults: userDefaults)

            userDefaults.removePersistentDomain(forName: storageName)
        }

        deinit {
            userDefaults.removePersistentDomain(forName: name)
        }
    }

    @CredentialActor
    func testDefaultCredentialViaToken() async throws {
        let context = TestContext(named: name)
        let storage = context.storage
        Credential.tokenStorage = storage

        _ = try TaskData.coordinator.store(token: token, tags: [:], security: [])

        XCTAssertEqual(storage.allIDs.count, 1)
        
        let credential = try XCTUnwrap(TaskData.coordinator.default)
        XCTAssertEqual(credential.token, token)
        
        TaskData.coordinator.default = nil
        XCTAssertNil(TaskData.coordinator.default)
        XCTAssertNil(storage.defaultTokenID)
        XCTAssertEqual(storage.allIDs.count, 1)
        
        XCTAssertEqual(TaskData.coordinator.allIDs, [token.id])
        XCTAssertEqual(try TaskData.coordinator.with(id: token.id, prompt: nil, authenticationContext: nil), credential)
    }
    
    @CredentialActor
    func testImplicitCredentialForToken() async throws {
        let context = TestContext(named: name)
        let storage = context.storage
        Credential.tokenStorage = storage

        let credential = try TaskData.coordinator.store(token: token, tags: [:], security: [])

        XCTAssertEqual(storage.allIDs, [token.id])
        XCTAssertEqual(storage.defaultTokenID, token.id)
        XCTAssertEqual(TaskData.coordinator.default, credential)
    }
    
    @CredentialActor
    func testNotifications() async throws {
        let context = TestContext(named: name)
        let storage = context.storage
        Credential.tokenStorage = storage

        let notificationCenter = NotificationCenter()
        try await TaskData.$notificationCenter.withValue(notificationCenter) {
            let oldCredential = TaskData.coordinator.default

            let recorder = NotificationRecorder(center: notificationCenter,
                                                observing: [.defaultCredentialChanged])

            let credential = try TaskData.coordinator.store(token: token, tags: [:], security: [])
            usleep(useconds_t(2000))
            await MainActor.run {
                XCTAssertEqual(recorder.notifications.count, 1)
                XCTAssertEqual(recorder.notifications.first?.object as? Credential, credential)
                XCTAssertNotEqual(oldCredential, credential)
                recorder.reset()
            }

            TaskData.coordinator.default = nil
            usleep(useconds_t(2000))
            await MainActor.run {
                XCTAssertEqual(recorder.notifications.count, 1)
                XCTAssertNil(recorder.notifications.first?.object)
                recorder.reset()
            }
        }
    }
}
