//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@inlinable
public func repeatedlyConfirmClosure<R: Sendable, E: Error>(
    _ comment: Comment? = nil,
    closureCount: Int = 4,
    isolation: isolated (any Actor)? = #isolation,
    sourceLocation: SourceLocation = #_sourceLocation,
    timeout: TimeInterval? = nil,
    _ body: @Sendable @escaping (Int, (@Sendable @escaping (Result<R, E>) -> Void)) -> Void) async throws -> [R]
{
    try await confirmation(comment,
                           expectedCount: closureCount,
                           isolation: isolation,
                           sourceLocation: sourceLocation) { confirm in
        try await withTimeout(timeout) {
            try await withThrowingTaskGroup(of: R.self) { group in
                for index in 1...closureCount {
                    group.addTask {
                        try await withCheckedThrowingContinuation { continuation in
                            body(index) { result in
                                confirm()
                                continuation.resume(with: result)
                            }
                        }
                    }
                }
                
                var results: [R] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
        }
    }
}

@inlinable
public func confirmClosure<R: Sendable, E: Error>(
    _ comment: Comment? = nil,
    isolation: isolated (any Actor)? = #isolation,
    sourceLocation: SourceLocation = #_sourceLocation,
    timeout: TimeInterval? = nil,
    _ body: @Sendable @escaping ((@Sendable @escaping (Result<R, E>) -> Void)) -> Void) async throws -> R
{
    try await confirmation(comment,
                           expectedCount: 1,
                           isolation: isolation,
                           sourceLocation: sourceLocation,
                           timeout: timeout) { confirm in
        try await withCheckedThrowingContinuation { continuation in
            body { result in
                confirm()
                continuation.resume(with: result)
            }
        }
    }
}

@inlinable
public func confirmClosure<E: Error>(
    _ comment: Comment? = nil,
    isolation: isolated (any Actor)? = #isolation,
    sourceLocation: SourceLocation = #_sourceLocation,
    timeout: TimeInterval? = nil,
    _ body: @Sendable @escaping ((@Sendable @escaping (Result<Void, E>) -> Void)) -> Void) async throws
{
    try await confirmation(comment,
                           expectedCount: 1,
                           isolation: isolation,
                           sourceLocation: sourceLocation,
                           timeout: timeout) { confirm in
        try await withCheckedThrowingContinuation { continuation in
            body { result in
                confirm()
                continuation.resume(with: result)
            }
        }
    }
}

@inlinable
public func confirmation<R: Sendable>(
  _ comment: Comment? = nil,
  expectedCount: Int = 1,
  isolation: isolated (any Actor)? = #isolation,
  sourceLocation: SourceLocation = #_sourceLocation,
  timeout: TimeInterval? = nil,
  _ body: @escaping @Sendable (Confirmation) async throws -> sending R
) async throws -> R {
  try await confirmation(
    comment,
    expectedCount: expectedCount ... expectedCount,
    isolation: isolation,
    sourceLocation: sourceLocation) { confirm in
        try await withTimeout(.long) {
            try await body(confirm)
        }
    }
}

@inlinable
public func withTimeout<R: Sendable>(
    _ timeout: TimeInterval?,
    _ body: @escaping @Sendable () async throws -> sending R
) async throws -> R {
    guard let timeout else {
        return try await body()
    }
    
    return try await withThrowingTaskGroup(of: R.self) { taskGroup in
        taskGroup.addTask {
            try await body()
        }
        taskGroup.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw CancellationError()
        }
        
        guard let result = try await taskGroup.next()
        else {
            throw CancellationError()
        }
        taskGroup.cancelAll()

        return result
    }
}
