/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

/// Errors reported from IDXClient
public enum IDXClientError: Error {
    case invalidClient
    case cannotCreateRequest
    case invalidHTTPResponse
    case invalidResponseData
    case invalidRequestData
    case serverError(message: String, localizationKey: String, type: String)
    case internalError(message: String)
    case invalidParameter(name: String)
    case invalidParameterValue(name: String, type: String)
    case parameterImmutable(name: String)
    case missingRequiredParameter(name: String)
    case unknownRemediationOption(name: String)
    case successResponseMissing
}

@objc
public protocol IDXClientAPI {
    /// Performs a request to interact with IDX, based on configured client options.
    /// - Parameters:
    ///   - completion: Invoked when a response, or error, is received.
    ///   - context: An object describing the context of the IDX interaction, or `nil` if the client configuration was invalid.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc func interact(completion: @escaping(_ context: IDXClient.Context?, _ error: Error?) -> Void)
    
    /// Introspects the authentication state to identify the available remediation steps.
    ///
    /// Once an interaction handle is received, this method can be used to determine what remedation options are available to the user to authenticate.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - interactionHandle: Interaction handle used to introspect the state.
    ///   - completion: Optional completion handler invoked when a response is received.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc func introspect(_ interactionHandle: String,
                          completion: ((_ reponse: IDXClient.Response?, _ error: Error?) -> Void)?)

    /// Indicates whether or not the current stage in the workflow can be cancelled.
    @objc var canCancel: Bool { get }
    
    /// Cancels and restarts the current workflow.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` method to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Invoked when the operation is cancelled.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc func cancel(completion: ((_ response: IDXClient.Response?, _ error: Error?) -> Void)?)
    
    /// Proceeds to the given remediation option.
    /// - Parameters:
    ///   - option: Remediation option to proceed to.
    ///   - data: Data to supply to the remediation step.
    ///   - completion: Invoked when a response, or error, is received.
    ///   - response: The response describing the next steps available in this workflow.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc func proceed(remediation option: IDXClient.Remediation.Option,
                       data: [String : Any],
                       completion: ((_ response: IDXClient.Response?, _ error: Swift.Error?) -> Void)?)
    
    /// Exchanges the successful response with a token.
    ///
    /// Once the `IDXClient.Response.isLoginSuccessful` property is `true`, the developer can exchange that response for a valid token by using this method.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didExchangeToken:)` method to receive the token or to handle any errors.
    /// - Parameters:
    ///   - response: Successful response.
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    ///   - token: The token that was exchanged, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc func exchangeCode(using response: IDXClient.Response,
                            completion: ((_ token: IDXClient.Token?, _ error: Swift.Error?) -> Void)?)
}
