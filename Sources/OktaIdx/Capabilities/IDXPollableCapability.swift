//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import AuthFoundation

/// Capability for authentiators or remedations to be polled to determine out-of-band actions taken by the user.
public final class PollCapability: Capability, Sendable, Equatable, Hashable {
    /// Indicates whether or not this authenticator is actively polling.
    public var isPolling: Bool {
        lock.withLock { _taskHandle != nil }
    }

    /// Starts the polling process.
    ///
    /// The action will be continually polled in the background either until ``cancel`` is called, or when the authenticator has finished. The result is returned once the user has completed the action out-of-band, or when an error is received.
    public func proceed() async throws -> Response {
        // Stop any previous polling
        cancel()

        return try await withExpression {
            guard flow != nil else {
                throw InteractionCodeFlowError.invalidFlow
            }

            let authenticatorType = self.authenticatorType
            let taskHandle = Task {
                let poll = try APIRequestPollingHandler<InteractionCodeFlow.RemediationRequest, Response>(
                    interval: refresh,
                    options: [.delayFirstRequest, .ignoreLostNetworkConnection, .default]) { pollingHandler, request in
                        guard let flow = self.flow else {
                            throw InteractionCodeFlowError.invalidFlow
                        }

                        let result = try await request.send(to: flow.client).result
                        let response = try Response(flow: flow, ion: result)

                        guard let currentAuthenticator = response.authenticators.current,
                              currentAuthenticator.type == authenticatorType,
                              let nextPoll = currentAuthenticator.pollable,
                              nextPoll.relatesTo == self.relatesTo
                        else {
                            return .success(response)
                        }

                        let nextRequest = try nextPoll.remediation.apiRequest()
                        self.remediation = nextPoll.remediation
                        return .continueWith(request: nextRequest,
                                             interval: nextPoll.remediation.refresh)
                }

                return try await poll.start(with: try remediation.apiRequest())
            }

            lock.withLock {
                _taskHandle = taskHandle
            }

            return try await taskHandle.value
        } success: { result in
            guard let flow = flow as? InteractionCodeFlow else { return }
            Task { @MainActor in
                flow.delegateCollection.invoke { $0.authentication(flow: flow, received: result) }
            }
        } failure: { error in
            guard let flow = flow as? InteractionCodeFlow else { return }
            Task { @MainActor in
                flow.delegateCollection.invoke { $0.authentication(flow: flow, received: OAuth2Error(error)) }
            }
        }
    }

    /// Stops the polling process from continuing.
    public func cancel() {
        lock.withLock {
            _taskHandle?.cancel()
            _taskHandle = nil
        }
    }

    @_documentation(visibility: internal)
    public static func == (lhs: PollCapability, rhs: PollCapability) -> Bool {
        lhs === rhs
    }

    @_documentation(visibility: internal)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(refresh)
        hasher.combine(authenticatorType)
    }

    let authenticatorType: Authenticator.Kind
    let refresh: TimeInterval
    let relatesTo: [String]?
    private let lock = Lock()
    var remediation: Remediation {
        get { lock.withLock { _remediation } }
        set { lock.withLock { _remediation = newValue } }
    }

    nonisolated(unsafe) private(set) weak var flow: (any InteractionCodeFlowAPI)?
    nonisolated(unsafe) private var _remediation: Remediation
    nonisolated(unsafe) private var _taskHandle: Task<Response, any Error>?
    internal init(flow: any InteractionCodeFlowAPI,
                  authenticatorType: Authenticator.Kind,
                  remediation: Remediation)
    {
        self.flow = flow
        self._remediation = remediation
        self.authenticatorType = authenticatorType
        self.relatesTo = remediation.relatesTo
        self.refresh = remediation.refresh ?? 5.0
    }
}

extension PollCapability {
    /// Starts the polling process.
    ///
    /// The action will be continually polled in the background either until ``cancel`` is called, or when the authenticator has finished. The result is returned once the user has completed the action out-of-band, or when an error is received.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    public func proceed(completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await proceed()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
