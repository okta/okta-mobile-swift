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

/// A threadsafe wrapper that coalesces multiple concurrent requests for the same asynchronous result, ensuring that only a single activec operation is performed, while allowing each caller to receive the result.
///
/// This is commonly used to limit unnecessary duplication of network operations for common resources.
@_documentation(visibility: private)
public actor CoalescedResult<T: Sendable>: Sendable {
    private let taskName: String?
    private var task: BackgroundTask?
    private var continuations: [CheckedContinuation<T, any Error>] = []
    private var _value: T?
    private var _isActive: Bool = false  {
        didSet {
            if _isActive, let taskName {
                task = BackgroundTask(named: taskName)
            } else if let task {
                task.finish()
                self.task = nil
            }
        }
    }

    /// Designated initializer.
    /// - Parameter taskName: The name of a background task to initiate while the operation is active.
    public init(taskName: String? = nil) {
        self.taskName = taskName
    }

    /// Indicates if the asynchronous operation is being performed.
    nonisolated public var isActive: Bool {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: Bool = false
        Task {
            result = await self._isActive
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    /// Stores the previously-fetched value, if one has been fetched and its response was successful.
    nonisolated public var value: T? {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: T?
        Task {
            result = await self._value
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    /// Performs an asynchronous operation, while ensuring that multiple concurrent requests do not result in multiple active tasks.
    /// - Parameters:
    ///   - reset: Resets any previously fetched value before starting.
    ///   - operation: Asynchronous operation used to fetch the value.
    ///   - willBegin: Optional closure to invoke before beginning the operation.
    ///   - didEnd: Optional closure to invoke with the result after the operation completes.
    /// - Returns: The value of type `T`.
    public func perform(reset: Bool = false,
                        operation: @Sendable () async throws -> T,
                        willBegin: @Sendable () -> Void = {},
                        didEnd: @Sendable (Result<T, any Error>) -> Void = { _ in }) async throws -> T
    {
        if reset {
            _value = nil
        }

        if !_isActive {
            if let value = _value {
                return value
            }

            _isActive = true
            task = BackgroundTask(named: taskName)
            willBegin()

            do {
                let result = try await operation()
                _value = result
                complete(with: .success(result), didEnd: didEnd)
                return result
            } catch {
                complete(with: .failure(error), didEnd: didEnd)
                throw error
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    private func complete(with result: Result<T, any Error>, didEnd: (Result<T, any Error>) -> Void) {
        _isActive = false

        continuations.forEach { $0.resume(with: result) }
        continuations.removeAll()

        task?.finish()
        task = nil

        didEnd(result)
    }
}
