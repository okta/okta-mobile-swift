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

import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class CredentialInternalTests: XCTestCase {
    @CredentialActor
    func testShouldRemoveWithOnlyAccessToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [])
        XCTAssertTrue(credential.shouldRemove(for: .all))
        XCTAssertTrue(credential.shouldRemove(for: .accessToken))
        XCTAssertFalse(credential.shouldRemove(for: .refreshToken))
        XCTAssertFalse(credential.shouldRemove(for: .deviceSecret))
    }

    @CredentialActor
    func testShouldRemoveWithAccessAndRefreshToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.refreshToken])
        XCTAssertTrue(credential.shouldRemove(for: .all))
        XCTAssertFalse(credential.shouldRemove(for: .accessToken))
        XCTAssertTrue(credential.shouldRemove(for: .refreshToken))
        XCTAssertFalse(credential.shouldRemove(for: .deviceSecret))
    }

    @CredentialActor
    func testShouldRemoveWithAccessAndDeviceToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.deviceSecret])
        XCTAssertTrue(credential.shouldRemove(for: .all))
        XCTAssertTrue(credential.shouldRemove(for: .accessToken))
        XCTAssertFalse(credential.shouldRemove(for: .refreshToken))
        XCTAssertFalse(credential.shouldRemove(for: .deviceSecret))
    }

    @CredentialActor
    func testShouldRemoveWithAccessRefreshAndDeviceToken() async throws {
        let coordinator = MockCredentialCoordinator()
        let credential = coordinator.credential(with: [.refreshToken, .deviceSecret])
        XCTAssertTrue(credential.shouldRemove(for: .all))
        XCTAssertFalse(credential.shouldRemove(for: .accessToken))
        XCTAssertTrue(credential.shouldRemove(for: .refreshToken))
        XCTAssertFalse(credential.shouldRemove(for: .deviceSecret))
    }
}
