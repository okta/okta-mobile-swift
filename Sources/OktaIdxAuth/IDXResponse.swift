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

/// Describes the response from an Okta Identity Engine workflow stage.
///
/// This is used to determine the current state of the workflow, the set of available ``Remediation`` steps to that can be used to proceed through the workflow, actions that can be performed, and other information relevant to the authentication of a user.
public final class Response: Sendable, Hashable, Equatable {
    /// The date at which this stage of the workflow expires, after which the authentication process should be restarted.
    public let expiresAt: Date?
    
    /// A string describing the intent of the workflow, e.g. "LOGIN".
    public let intent: Intent
    
    /// An object describing the sort of remediation steps available to the user.
    public let remediations: Remediation.Collection
    
    /// Contains information about the available authenticators.
    public let authenticators: Authenticator.Collection
    
    /// Returns information about the application, if available.
    public let app: Application?
    
    /// Returns information about the user authenticating, if available.
    public let user: User?
    
    /// The list of messages sent from the server.
    ///
    /// ``Message`` objects reported from the server are usually errors, but may include other information relevant to the user. They should be displayed to the user in the context of the remediation form itself.
    public let messages: Response.Message.Collection
    
    /// Indicates whether or not the user has logged in successfully. If this is `true`, this response object should be exchanged for access tokens utilizing the ``finish()`` method.
    public let isLoginSuccessful: Bool
    
    /// Indicates whether or not the response can be cancelled.
    public let canRestart: Bool

    /// Cancels and restarts the current session.
    public func restart() async throws -> Response {
        guard let cancelOption = remediations[.cancel] else {
            throw InteractionCodeFlowError.missingRemediation(name: "cancel")
        }

        return try await flow.resume(with: cancelOption)
    }
    
    /// Finishes sign-in, exchanging the successful response with a token.
    ///
    /// Once the ``isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    public func finish() async throws -> Token {
        try await flow.resume(with: self)
    }
    
    @_documentation(visibility: internal)
    public static func == (lhs: Response, rhs: Response) -> Bool {
        lhs.expiresAt == rhs.expiresAt &&
        lhs.intent == rhs.intent &&
        lhs.remediations == rhs.remediations &&
        lhs.authenticators == rhs.authenticators &&
        lhs.app == rhs.app &&
        lhs.user == rhs.user &&
        lhs.isLoginSuccessful == rhs.isLoginSuccessful &&
        lhs.successRemediationOption == rhs.successRemediationOption &&
        lhs.messages == rhs.messages
    }

    @_documentation(visibility: internal)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(expiresAt)
        hasher.combine(intent)
        hasher.combine(remediations)
        hasher.combine(authenticators)
        hasher.combine(app)
        hasher.combine(user)
        hasher.combine(isLoginSuccessful)
        hasher.combine(successRemediationOption)
        hasher.combine(messages)
    }

    private let flow: any InteractionCodeFlowAPI
    let successRemediationOption: Remediation?
    internal init(flow: any InteractionCodeFlowAPI,
                  expiresAt: Date?,
                  intent: Intent,
                  authenticators: Authenticator.Collection,
                  remediations: Remediation.Collection,
                  successRemediationOption: Remediation?,
                  messages: Response.Message.Collection,
                  app: Response.Application?,
                  user: Response.User?)
    {
        self.flow = flow
        self.expiresAt = expiresAt
        self.intent = intent
        self.authenticators = authenticators
        self.remediations = remediations
        self.successRemediationOption = successRemediationOption
        self.isLoginSuccessful = successRemediationOption != nil
        self.messages = messages
        self.app = app
        self.user = user
        self.canRestart = (remediations[.cancel] != nil)
    }
}

extension Response {
    /// Cancels and restarts the current session.
    ///
    /// - Parameter completion: Completion handler invoked when the operation is cancelled.
    nonisolated public func restart(completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await restart()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Finishes sign-in, exchanging the successful response with a token.
    ///
    /// Once the ``isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    /// - Parameter completion: Completion handler invoked when a token, or error, is received.
    nonisolated public func finish(completion: @escaping @Sendable (Result<Token, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await finish()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
