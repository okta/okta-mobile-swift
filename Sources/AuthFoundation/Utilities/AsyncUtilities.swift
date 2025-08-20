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

import Foundation

/// Shared TaskLocal data used within AuthFoundation tasks.
///
/// This is primarily used by unit tests to ensure the consistent passage of shared framework objects to isolate tests.
@_documentation(visibility: internal)
public enum TaskData {
    /// The shared Credential Coordinator implementation.
    @TaskLocal static var coordinator: CredentialCoordinatorImpl = CredentialCoordinatorImpl()

    /// The NotificationCenter instance that should be used when posting or observing notifications.
    @TaskLocal public static var notificationCenter: NotificationCenter = .default

    /// The factor used to convert a time interval to nanoseconds.
    ///
    /// > Important: This is only used for testing, and should not be used in production.
    @TaskLocal static var timeIntervalToNanoseconds: Double = 1_000_000_000
}

extension Task where Success == Never, Failure == Never {
    static func sleep(delay: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(delay * TaskData.timeIntervalToNanoseconds))
    }
}

/// Shared actor used to coordinate multithreaded interactions within the Credential storage subsystem.
@globalActor
@_documentation(visibility: private)
public final actor CredentialActor {
    public static let shared = CredentialActor()
    
    /// Convenience for running a block within the context of the ``CredentialActor``.
    /// - Parameter body: Block to execute.
    /// - Returns: Result of the block.
    public static func run<T: Sendable>(_ body: @CredentialActor @Sendable () throws -> T) async rethrows -> T {
        try await body()
    }
}

