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

extension IDXClient {
    /// Describes the response from an Okta Identity Engine workflow stage. This is used to determine the current state of the workflow, the set of available remediation steps to proceed through the workflow, actions that can be performed, and other information relevant to the authentication of a user.
    @objc(IDXResponse)
    public class Response: NSObject {
        /// The date at which this stage of the workflow expires, after which the authentication process should be restarted.
        @objc public let expiresAt: Date?
        
        /// A string describing the intent of the workflow, e.g. "LOGIN".
        @objc public let intent: Intent
        
        /// An object describing the sort of remediation steps available to the user.
        @objc public let remediations: RemediationCollection
        
        /// Contains information about the available authenticators.
        @objc public let authenticators: AuthenticatorCollection

        /// Returns information about the application, if available.
        @objc public let app: IDXClient.Application?
        
        /// Returns information about the user authenticating, if available.
        @objc public let user: IDXClient.User?

        /// The list of messages sent from the server.
        ///
        /// Messages reported from the server are usually errors, but may include other information relevant to the user. They should be displayed to the user in the context of the remediation form itself.
        @objc public let messages: MessageCollection

        /// Indicates whether or not the user has logged in successfully. If this is `true`, this response object should be exchanged for access tokens utilizing the `exchangeCode` method.
        @objc public let isLoginSuccessful: Bool
        
        /// Indicates whether or not the response can be cancelled.
        @objc public let canCancel: Bool
        
        /// Cancels the current workflow, and restats the session.
        ///
        /// - Important:
        /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
        /// - Parameters:
        ///   - completion: Optional completion handler invoked when the operation is cancelled.
        ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
        ///   - error: Describes the error that occurred, or `nil` if successful.
        @objc public func cancel(completion: ((_ response: Response?, _ error: Error?) -> Void)?) {
            guard let cancelOption = remediations[.cancel] else {
                completion?(nil, IDXClientError.unknownRemediationOption(name: "cancel"))
                return
            }
            
            cancelOption.proceed(completion: completion)
        }
        
        /// Exchanges the successful response with a token.
        ///
        /// Once the `isLoginSuccessful` property is `true`, the developer can exchange the response for a valid token by using this method.
        /// - Important:
        /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` method to receive the token or to handle any errors.
        /// - Parameters:
        ///   - completion: Optional completion handler invoked when a token, or error, is received.
        ///   - token: The token that was exchanged, or `nil` if an error occurred.
        ///   - error: Describes the error that occurred, or `nil` if successful.
        @objc public func exchangeCode(completion: ((_ token: Token?, _ error: Error?) -> Void)?) {
            guard let successOption = successRemediationOption else {
                completion?(nil, IDXClientError.successResponseMissing)
                return
            }
            
            client.exchangeCode(using: successOption, completion: completion)
        }
        
        private let client: IDXClientAPI
        let successRemediationOption: Remediation?
        internal init(client: IDXClientAPI,
                      expiresAt: Date?,
                      intent: Intent,
                      authenticators: AuthenticatorCollection,
                      remediations: RemediationCollection,
                      successRemediationOption: Remediation?,
                      messages: MessageCollection,
                      app: Application?,
                      user: User?)
        {
            self.client = client
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
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [
                logger.address(),
                "\(#keyPath(intent)): \(intent.rawValue)",
                "\(#keyPath(isLoginSuccessful)): \(isLoginSuccessful)",
                "\(#keyPath(expiresAt)): \(expiresAt?.debugDescription ?? "-")",
            ]

            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            let components = [
                "\(#keyPath(remediations)): \(remediations.debugDescription)",
                "\(#keyPath(authenticators)): \(authenticators.debugDescription)",
                "\(#keyPath(app)): \(app?.debugDescription ?? "-")",
                "\(#keyPath(messages)): \(messages.debugDescription)"
            ]
            
            return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
        }
        
    }
}
