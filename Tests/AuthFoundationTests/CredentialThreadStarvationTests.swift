//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Tests that verify the CredentialActor's custom GCD-backed executor prevents
/// cooperative thread pool starvation when synchronous bridges
/// (withIsolationSync / withIsolationSyncThrowing) are called from async contexts.
///
/// ## Background
/// Prior to the custom executor fix, `withIsolationSyncThrowing` used
/// `DispatchGroup.wait()` to block the current thread while spawning a `Task`
/// to execute `@CredentialActor`-isolated work. When the calling thread was part
/// of the Swift cooperative pool (e.g. inside a `Task`), this could exhaust the
/// pool and deadlock — the inner Task needed a cooperative thread to run, but
/// all threads were blocked by `group.wait()`.
///
/// The fix gives `CredentialActor` a `DispatchQueue`-backed `SerialExecutor`,
/// so actor-isolated work runs on GCD threads instead of the cooperative pool.
final class CredentialThreadStarvationTests: XCTestCase {

    var coordinator: MockCredentialCoordinator!

    override func setUp() async throws {
        coordinator = await MockCredentialCoordinator()
    }

    override func tearDown() async throws {
        coordinator = nil
    }

    /// Reproduces the original deadlock scenario: many concurrent async tasks
    /// all calling synchronous Credential APIs that bridge to
    /// `@CredentialActor` via `withIsolationSyncThrowing`.
    ///
    /// Without the custom executor, this test would hang/crash with thread
    /// starvation (EXC_BAD_ACCESS / SIGTRAP) because `group.wait()` blocks
    /// cooperative threads while the actor's Task needs one to run.
    ///
    /// With the custom executor, the actor work runs on a GCD queue,
    /// so blocking cooperative threads is harmless.
    func testConcurrentSyncBridgeFromAsyncContextDoesNotDeadlock() async throws {
        // Use enough concurrent tasks to saturate the cooperative thread pool.
        // The pool is typically sized to the number of CPU cores. Using a large
        // multiplier ensures we exceed it even on high-core-count machines.
        let taskCount = ProcessInfo.processInfo.activeProcessorCount * 4
        let timeout: TimeInterval = 10.0

        // Create credentials to work with
        var credentials: [Credential] = []
        for i in 0..<taskCount {
            let token = Token.mockToken(id: "StarvationTest-\(i)")
            let credential = await coordinator.credentialDataSource.credential(
                for: token,
                coordinator: coordinator
            )
            credentials.append(credential)
        }

        // Launch many concurrent tasks that all call sync APIs which use
        // withIsolationSyncThrowing under the hood. If the custom executor
        // is not in place, this will deadlock.
        let completed = expectation(description: "All tasks completed")
        completed.expectedFulfillmentCount = taskCount

        for credential in credentials {
            Task {
                // This calls withIsolationSyncThrowing internally
                try credential.remove()
                completed.fulfill()
            }
        }

        await fulfillment(of: [completed], timeout: timeout)
    }

    /// Verifies that calling `Credential.store()` (sync, via
    /// `withIsolationSyncThrowing`) concurrently from many async tasks
    /// does not deadlock.
    func testConcurrentStoreFromAsyncContextDoesNotDeadlock() async throws {
        let taskCount = ProcessInfo.processInfo.activeProcessorCount * 4
        let timeout: TimeInterval = 10.0

        await CredentialActor.run {
            Credential.tokenStorage = MockTokenStorage()
            Credential.credentialDataSource = MockCredentialDataSource()
        }

        let completed = expectation(description: "All store tasks completed")
        completed.expectedFulfillmentCount = taskCount

        for i in 0..<taskCount {
            Task {
                let token = Token.mockToken(id: "StoreTest-\(i)")
                _ = try Credential.store(token)
                completed.fulfill()
            }
        }

        await fulfillment(of: [completed], timeout: timeout)

        // Wait briefly for any deferred notifications to drain before resetting
        try await Task.sleep(nanoseconds: 100_000_000)
        await CredentialActor.run {
            Credential.resetToDefault()
        }
    }

    /// Tests the exact crash scenario from the customer report:
    /// `credential.revoke()` (async) internally calls `withIsolationSyncThrowing`
    /// to remove the credential from storage after revoking on the server.
    ///
    /// Multiple concurrent revoke calls from async contexts would exhaust the
    /// cooperative pool without the custom executor.
    func testConcurrentRevokeFromAsyncContextDoesNotDeadlock() async throws {
        let taskCount = ProcessInfo.processInfo.activeProcessorCount * 4
        let timeout: TimeInterval = 10.0

        var credentials: [Credential] = []
        for i in 0..<taskCount {
            let token = Token.mockToken(
                id: "RevokeTest-\(i)",
                refreshToken: "refresh-\(i)"
            )
            let credential = await coordinator.credentialDataSource.credential(
                for: token,
                coordinator: coordinator
            )

            // Set up mock responses for revoke network calls
            if let urlSession = credential.oauth2.session as? URLSessionMock {
                urlSession.expect(
                    "https://example.com/.well-known/openid-configuration",
                    data: try data(from: .module,
                                   for: "openid-configuration",
                                   in: "MockResponses"),
                    contentType: "application/json"
                )
                // Revoke endpoint for access token
                urlSession.expect(
                    "https://example.com/oauth2/v1/revoke",
                    data: Data()
                )
                // Revoke endpoint for refresh token
                urlSession.expect(
                    "https://example.com/oauth2/v1/revoke",
                    data: Data()
                )
            }

            credentials.append(credential)
        }

        let completed = expectation(description: "All revoke tasks completed")
        completed.expectedFulfillmentCount = taskCount

        for credential in credentials {
            Task {
                // This is the exact pattern from the customer's crash:
                // async function -> revoke() -> withIsolationSyncThrowing
                try await credential.revoke(type: .all)
                completed.fulfill()
            }
        }

        await fulfillment(of: [completed], timeout: timeout)
    }

    /// Verifies that mixed concurrent access to multiple sync Credential APIs
    /// from async contexts does not deadlock. This simulates a realistic app
    /// scenario where different operations happen simultaneously.
    func testMixedConcurrentOperationsDoNotDeadlock() async throws {
        let operationsPerType = ProcessInfo.processInfo.activeProcessorCount * 2
        let totalOperations = operationsPerType * 3
        let timeout: TimeInterval = 15.0

        await CredentialActor.run {
            Credential.tokenStorage = MockTokenStorage()
            Credential.credentialDataSource = MockCredentialDataSource()
        }

        let completed = expectation(description: "All mixed operations completed")
        completed.expectedFulfillmentCount = totalOperations

        // Store operations
        for i in 0..<operationsPerType {
            Task {
                let token = Token.mockToken(id: "MixedStore-\(i)")
                _ = try Credential.store(token)
                completed.fulfill()
            }
        }

        // allIDs reads (via withIsolationSync)
        for _ in 0..<operationsPerType {
            Task {
                _ = Credential.allIDs
                completed.fulfill()
            }
        }

        // default getter reads (via withIsolationSync)
        for _ in 0..<operationsPerType {
            Task {
                _ = Credential.default
                completed.fulfill()
            }
        }

        await fulfillment(of: [completed], timeout: timeout)

        // Wait briefly for any deferred notifications to drain before resetting
        try await Task.sleep(nanoseconds: 100_000_000)
        await CredentialActor.run {
            Credential.resetToDefault()
        }
    }
}
