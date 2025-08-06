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

import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(Android)
import Android
#endif

@testable import TestCommon
@testable import AuthFoundation

@Suite("User Coordinator Tests")
struct UserCoordinatorTests {
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
    
    @Test("Default credential set implicitly from stored token", .credentialCoordinator(style: .userDefaultStorage))
    @CredentialActor
    func testDefaultCredentialViaToken() async throws {
        let coordinator = Credential.providers.coordinator
        let storage = try #require(coordinator.tokenStorage as? UserDefaultsTokenStorage)
        _ = try coordinator.store(token: token, tags: [:], security: [])

        #expect(storage.allIDs.count == 1)
        
        let credential = try #require(coordinator.default)
        #expect(credential.token == token)
        
        coordinator.default = nil
        #expect(coordinator.default == nil)
        #expect(storage.defaultTokenID == nil)
        #expect(storage.allIDs.count == 1)
        
        #expect(coordinator.allIDs == [token.id])
        #expect(try coordinator.with(id: token.id, prompt: nil, authenticationContext: nil) == credential)
    }
    
    @CredentialActor
    func testImplicitCredentialForToken() async throws {
        let coordinator = Credential.providers.coordinator
        let storage = try #require(coordinator.tokenStorage as? UserDefaultsTokenStorage)

        let credential = try coordinator.store(token: token, tags: [:], security: [])

        #expect(storage.allIDs == [token.id])
        #expect(storage.defaultTokenID == token.id)
        #expect(coordinator.default == credential)
    }
    
    @CredentialActor
    func testNotifications() async throws {
        let coordinator = Credential.providers.coordinator

        let notificationCenter = NotificationCenter()
        try await TaskData.$notificationCenter.withValue(notificationCenter) {
            let oldCredential = coordinator.default

            let recorder = NotificationRecorder(center: notificationCenter,
                                                observing: [.defaultCredentialChanged])

            let credential = try coordinator.store(token: token, tags: [:], security: [])
            usleep(useconds_t(2000))
            await MainActor.run {
                #expect(recorder.notifications.count == 1)
                #expect(recorder.notifications.first?.object as? Credential == credential)
                #expect(oldCredential != credential)
                recorder.reset()
            }

            coordinator.default = nil
            usleep(useconds_t(2000))
            await MainActor.run {
                #expect(recorder.notifications.count == 1)
                #expect(recorder.notifications.first?.object == nil)
                recorder.reset()
            }
        }
    }
}
