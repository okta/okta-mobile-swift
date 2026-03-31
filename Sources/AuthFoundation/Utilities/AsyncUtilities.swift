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

private final class DispatchQueueExecutor: SerialExecutor {
     private let queue: DispatchQueue

     init(queue: DispatchQueue) {
         self.queue = queue
     }

     func enqueue(_ job: UnownedJob) {
         self.queue.async {
             job.runSynchronously(on: self.asUnownedSerialExecutor())
         }
     }

     func asUnownedSerialExecutor() -> UnownedSerialExecutor {
         UnownedSerialExecutor(ordinary: self)
     }

    func checkIsolated() {
        dispatchPrecondition(condition: .onQueue(self.queue))
    }
}

/// Strips `@CredentialActor` isolation from a closure's type signature.
///
/// Swift's type system treats `@CredentialActor () -> T` and `() -> T` as
/// distinct types. When executing on the actor's serial GCD queue (via
/// `queue.sync`), we are *semantically* within the actor's isolation domain
/// — the custom ``DispatchQueueExecutor`` guarantees this, and its
/// `checkIsolated()` method provides a runtime assertion.
///
/// However, the compiler can't statically verify that `queue.sync` provides
/// the actor's isolation. There is currently no first-class Swift API to
/// express "Trust me, I'm on this global actor's executor." Until an API exists,
/// `unsafeBitCast` is used to reinterpret the closure type.
///
/// This is safe because:
/// 1. The closure's ABI representation is identical with or without the
///    `@CredentialActor` attribute — it only affects compile-time checking.
/// 2. The ``sync`` guarantees execution on the
///    actor's serial queue before invoking the result.
@inline(__always)
private nonisolated func stripIsolation<T>(
    _ body: @CredentialActor @Sendable @escaping () throws -> T
) -> @Sendable () throws -> T {
    unsafeBitCast(body, to: (@Sendable () throws -> T).self)
}

/// Shared actor used to coordinate multithreaded interactions within the Credential storage subsystem.
@globalActor
@_documentation(visibility: private)
public final actor CredentialActor {
    public static let shared = CredentialActor()

    private let queue = DispatchQueue(label: "com.okta.credential-actor")
    private let executor: DispatchQueueExecutor

    private init() {
        self.executor = DispatchQueueExecutor(queue: queue)
    }

    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    /// Convenience for running a block within the context of the ``CredentialActor``.
    /// - Parameter body: Block to execute.
    /// - Returns: Result of the block.
    public static func run<T: Sendable>(_ body: @CredentialActor @Sendable () throws -> T) async rethrows -> T {
        try await body()
    }

    /// Synchronously executes a block on the ``CredentialActor``'s serial queue,
    /// blocking the caller until completion.
    ///
    /// This dispatches directly to the actor's GCD queue using `DispatchQueue.sync`,
    /// bypassing the Swift cooperative thread pool. This prevents deadlocks that can occur
    /// when all cooperative threads are blocked by `DispatchGroup.wait()`.
    ///
    /// > Warning: This is intended for the exclusive use of synchronous use-cases that interact with the credential storage sub-system. It may be made public at some point, but is being kept `internal` until it is required.
    ///
    /// - Parameter body: Block to execute on the actor's serial queue.
    /// - Returns: The result of the block.
    /// - Throws: Any error thrown by the block.
    nonisolated static func sync<T: Sendable>(_ body: @CredentialActor @Sendable @escaping () throws -> T) rethrows -> T {
        let rawBody = stripIsolation(body)
        return try shared.queue.sync {
            try rawBody()
        }
    }
}
