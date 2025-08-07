//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@testable import TestCommon
@testable import AuthFoundation

@Suite("Credential removal upon revocation", .disabled("Debugging test deadlocks within CI"))
struct CredentialRevocationRemovalTests {
    @Test("Remove when only an access token is present")
    @CredentialActor
    func testShouldRemoveWithOnlyAccessToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [])
        #expect(credential.shouldRemove(for: .all))
        #expect(credential.shouldRemove(for: .accessToken))
        #expect(!credential.shouldRemove(for: .refreshToken))
        #expect(!credential.shouldRemove(for: .deviceSecret))
    }

    @Test("Remove when access and refresh token are present")
    @CredentialActor
    func testShouldRemoveWithAccessAndRefreshToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.refreshToken])
        #expect(credential.shouldRemove(for: .all))
        #expect(!credential.shouldRemove(for: .accessToken))
        #expect(credential.shouldRemove(for: .refreshToken))
        #expect(!credential.shouldRemove(for: .deviceSecret))
    }

    @Test("Remove when access and device token are present")
    @CredentialActor
    func testShouldRemoveWithAccessAndDeviceToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.deviceSecret])
        #expect(credential.shouldRemove(for: .all))
        #expect(credential.shouldRemove(for: .accessToken))
        #expect(!credential.shouldRemove(for: .refreshToken))
        #expect(!credential.shouldRemove(for: .deviceSecret))
    }

    @Test("Remove when access, refresh and device token are present")
    @CredentialActor
    func testShouldRemoveWithAccessRefreshAndDeviceToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.refreshToken, .deviceSecret])
        #expect(credential.shouldRemove(for: .all))
        #expect(!credential.shouldRemove(for: .accessToken))
        #expect(credential.shouldRemove(for: .refreshToken))
        #expect(!credential.shouldRemove(for: .deviceSecret))
    }
}
