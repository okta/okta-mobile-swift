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
    /// The NotificationCenter instance that should be used when posting or observing notifications.
    @TaskLocal public static var notificationCenter: NotificationCenter = .default
}

@_documentation(visibility: private)
public enum UtilityError: Error {
    case missingAsynchronousResult
}

/// Shared actor used to coordinate multithreaded interactions within the Credential storage subsystem.
@globalActor
@_documentation(visibility: private)
final public actor CredentialActor {
    public static let shared = CredentialActor()
    
    /// Convenience for running a block within the context of the ``CredentialActor``.
    /// - Parameter body: Block to execute.
    /// - Returns: Result of the block.
    public static func run<T: Sendable>(_ body: @CredentialActor @Sendable () throws -> T) async rethrows -> T {
        try await body()
    }
}

/// Convenience function that wraps an expression so that results, or thrown errors, can be propagated to the appropriate underlying delegate functions as necessary.
///
/// The implementation uses several Swift features to indicate to the compiler how to address actor isolation and handling of references to `self`. These mechanisms are used throughout the Swift Foundation Library, and while being subtle, are important to communicate task ownership.
///
/// For more information, see the following resources:
/// * https://developer.apple.com/forums/thread/761150
/// * https://github.com/swiftlang/swift/blob/main/docs/ReferenceGuides/UnderscoredAttributes.md#_inheritactorcontext
/// * https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md
/// 
/// - Parameters:
///   - expression: Expression to invoke which should be wrapped by the delegate collection
///   - success: Closure invoked when the expression is successful
///   - failure: Closure invoked when the expression throws an error
/// - Returns: The result when the expression is successful
@inlinable
@_documentation(visibility: private)
public func withExpression<T: Sendable>(
    @_inheritActorContext @_implicitSelfCapture _ expression: @isolated(any) @Sendable () async throws -> T,
    @_inheritActorContext @_implicitSelfCapture success: @isolated(any) @Sendable (T) -> Void = { _ in },
    @_inheritActorContext @_implicitSelfCapture failure: @isolated(any) @Sendable (any Error) throws -> Void = { _ in },
    @_inheritActorContext @_implicitSelfCapture finally: @isolated(any) @Sendable () -> Void = {}) async rethrows -> T
{
    do {
        let result = try await expression()
        await success(result)
        await finally()
        return result
    } catch {
        do {
            try await failure(error)
        } catch {
            await finally()
            throw error
        }
        await finally()
        throw error
    }
}

/// Executes a throwing asynchronous task within a synchronous context.
///
/// This utilizes a dispatch group to perform an async operation while ensuring the value can be returned synchronously.
/// - Parameters:
///   - priority: Optional task priority to use when initiating the task.
///   - block: Async throwing block to perform.
/// - Throws: Exception thrown from the block.
/// - Returns: Return value from the block.
@inlinable
@_documentation(visibility: private)
public func withIsolationSyncThrowing<T: Sendable>(priority: TaskPriority? = nil, @_inheritActorContext _ block: @Sendable @escaping () async throws -> T) throws -> T {
    let group = DispatchGroup()
    nonisolated(unsafe) var result: Result<T, any Error>?

    group.enter()
    Task(priority: priority) {
        defer { group.leave() }
        do {
            let value = try await block()
            result = .success(value)
        } catch {
            result = .failure(error)
        }
    }
    group.wait()
    
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        throw error
    case .none:
        throw UtilityError.missingAsynchronousResult
    }
}

/// Executes an asynchronous task within a synchronous context.
///
/// This utilizes a dispatch group to perform an async operation while ensuring the value can be returned synchronously.
///
/// > Note: This can only be used to return optional values.
/// - Parameters:
///   - priority: Optional task priority to use when initiating the task.
///   - block: Async throwing block to perform.
/// - Returns: Return value from the block.
@inlinable
@_documentation(visibility: private)
public func withIsolationSync<T: Sendable>(priority: TaskPriority? = nil,
                                           @_inheritActorContext _ block: @Sendable @escaping () async -> T?) -> T?
{
    let group = DispatchGroup()
    nonisolated(unsafe) var result: T?
    
    group.enter()
    Task(priority: priority) {
        defer { group.leave() }
        result = await block()
    }
    group.wait()
    
    return result
}
