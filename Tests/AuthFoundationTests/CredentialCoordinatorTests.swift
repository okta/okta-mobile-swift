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

    override func setUp() async throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)
        storage = await UserDefaultsTokenStorage(userDefaults: userDefaults)

        let mockStorage = storage
        await CredentialActor.run {
            Credential.tokenStorage = mockStorage!
        }

        let tokenCount = await storage.allIDs.count
        XCTAssertEqual(tokenCount, 0)
    }
    
    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: name)
        userDefaults = nil
        storage = nil

        await CredentialActor.run {
            Credential.resetToDefault()
        }
    }
    
    @CredentialActor
    func testDefaultCredentialViaToken() async throws {
        _ = try Credential.coordinator.store(token: token, tags: [:], security: [])

        XCTAssertEqual(storage.allIDs.count, 1)
        
        let credential = try XCTUnwrap(Credential.coordinator.default)
        XCTAssertEqual(credential.token, token)
        
        Credential.coordinator.default = nil
        XCTAssertNil(Credential.coordinator.default)
        XCTAssertNil(storage.defaultTokenID)
        XCTAssertEqual(storage.allIDs.count, 1)
        
        XCTAssertEqual(Credential.coordinator.allIDs, [token.id])
        XCTAssertEqual(try Credential.coordinator.with(id: token.id, prompt: nil, authenticationContext: nil), credential)
    }
    
    @CredentialActor
    func testImplicitCredentialForToken() async throws {
        let credential = try Credential.coordinator.store(token: token, tags: [:], security: [])

        XCTAssertEqual(storage.allIDs, [token.id])
        XCTAssertEqual(storage.defaultTokenID, token.id)
        XCTAssertEqual(Credential.coordinator.default, credential)
    }
    
    @CredentialActor
    func testNotifications() async throws {
        let notificationCenter = NotificationCenter()
        try await TaskData.$notificationCenter.withValue(notificationCenter) {
            let oldCredential = Credential.coordinator.default

            let recorder = NotificationRecorder(center: notificationCenter,
                                                observing: [.defaultCredentialChanged])

            let credential = try Credential.coordinator.store(token: token, tags: [:], security: [])
            usleep(useconds_t(2000))
            await MainActor.run {
                XCTAssertEqual(recorder.notifications.count, 1)
                XCTAssertEqual(recorder.notifications.first?.object as? Credential, credential)
                XCTAssertNotEqual(oldCredential, credential)
                recorder.reset()
            }

            Credential.coordinator.default = nil
            usleep(useconds_t(2000))
            await MainActor.run {
                XCTAssertEqual(recorder.notifications.count, 1)
                XCTAssertNil(recorder.notifications.first?.object)
                recorder.reset()
            }
        }
    }
}
