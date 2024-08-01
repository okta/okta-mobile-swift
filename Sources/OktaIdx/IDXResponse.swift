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
public class Response: NSObject {
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
    
    /// Indicates whether or not the user has logged in successfully. If this is `true`, this response object should be exchanged for access tokens utilizing the ``exchangeCode(completion:)`` method.
    public let isLoginSuccessful: Bool
    
    /// Indicates whether or not the response can be cancelled.
    public let canCancel: Bool
    
    /// Cancels the current workflow, and restarts the session.
    ///
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the ``InteractionCodeFlowDelegate`` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when the operation is cancelled.
    public func cancel(completion: InteractionCodeFlow.ResponseResult? = nil) {
        guard let cancelOption = remediations[.cancel] else {
            flow.send(error: .unknownRemediationOption(name: "cancel"), completion: completion)
            return
        }
        
        cancelOption.proceed(completion: completion)
    }
    
    /// Exchanges the successful response with a token.
    ///
    /// Once the ``isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the ``InteractionCodeFlowDelegate`` methods to receive the token or to handle any errors.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    public func exchangeCode(completion: InteractionCodeFlow.TokenResult? = nil) {
        guard let remediation = successRemediationOption else {
            completion?(.failure(.successResponseMissing))
            return
        }
        
        guard let context = flow.context else {
            flow.send(error: .invalidContext, completion: completion)
            return
        }
        
        guard remediation.name == "issue" else {
            flow.send(error: .successResponseMissing, completion: completion)
            return
        }
        
        flow.client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                self.exchangeCode(remediation: remediation,
                                  context: context,
                                  openIdConfiguration: configuration,
                                  completion: completion)
            case .failure(let error):
                self.flow.send(error: .internalError(error), completion: completion)
            }
        }
    }
    
    private func exchangeCode(remediation: Remediation,
                              context: InteractionCodeFlow.Context,
                              openIdConfiguration: OpenIdConfiguration,
                              completion: InteractionCodeFlow.TokenResult? = nil)
    {
        do {
            let tokenRequest = try InteractionCodeFlow.SuccessResponseTokenRequest(
                openIdConfiguration: openIdConfiguration,
                successResponse: remediation,
                clientId: flow.client.configuration.clientId,
                scope: flow.client.configuration.scopes,
                redirectUri: flow.redirectUri.absoluteString,
                context: context)
            flow.client.exchange(token: tokenRequest) { result in
                self.flow.reset()
                
                switch result {
                case .success(let token):
                    self.flow.send(response: token.result, completion: completion)
                    self.flow.reset()
                case .failure(let error):
                    self.flow.send(error: .apiError(error), completion: completion)
                }
            }
        } catch let error as InteractionCodeFlowError {
            flow.send(error: error, completion: completion)
            return
        } catch let error as APIClientError {
            flow.send(error: .apiError(error), completion: completion)
            return
        } catch {
            flow.send(error: .internalError(error), completion: completion)
            return
        }
    }
    
    private let flow: InteractionCodeFlowAPI
    let successRemediationOption: Remediation?
    internal init(flow: InteractionCodeFlowAPI,
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
        self.canCancel = (remediations[.cancel] != nil)
        
        super.init()
    }
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Response {
    /// Cancels the current workflow, and restarts the session.
    public func cancel() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            cancel() { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Exchanges the successful response with a token.
    ///
    /// Once the ``isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    public func exchangeCode() async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            exchangeCode() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
