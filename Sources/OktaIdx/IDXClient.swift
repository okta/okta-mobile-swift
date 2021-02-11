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

/// The IDXClient class is used to define and initiate an authentication workflow utilizing the Okta Identity Engine. Your app can use this to begin a customizable workflow to authenticate and verify the identity of a user using your application.
///
/// The `IDXClient.Configuration` class is used to communicate which application, defined within Okta, the user is being authenticated with. From this point a workflow is initiated, consisting of a series of authentication "Remediation" steps. At each step, your application can introspect the `IDXClient.Response` object to determine which UI should be presented to your user to guide them through to login.
@objc
public final class IDXClient: NSObject {
    /// The Okta Identity Engine API version to use.
    @objc(OKTIdentityEngineVersion)
    public enum Version: Int {
        /// API version 1.0.0
        case v1_0_0
    }
    
    /// Configuration options for an IDXClient.
    ///
    /// This class is used to define the configuration, as defined in your Okta application settings, that will be used to interact with the Okta Identity Engine API.
    @objc(IDXClientConfiguration)
    public final class Configuration: NSObject {
        /// The issuer URL.
        @objc public let issuer: String
        
        /// The application's client ID.
        @objc public let clientId: String
        
        /// The application's client secret, if required.
        @objc public let clientSecret: String?
        
        /// The access scopes required by the client.
        @objc public let scopes: [String]
        
        /// The application's redirect URI.
        @objc public let redirectUri: String

        /// Initializes an IDX configuration object.
        /// - Parameters:
        ///   - issuer: The issuer URL.
        ///   - clientId: The application's client ID.
        ///   - clientSecret: The application's client secret, if required.
        ///   - scopes: The application's access scopes.
        ///   - redirectUri: The application's redirect URI.
        @objc public init(issuer: String,
                          clientId: String,
                          clientSecret: String?,
                          scopes: [String],
                          redirectUri: String)
        {
            self.issuer = issuer
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.scopes = scopes
            self.redirectUri = redirectUri
            
            super.init()
        }
    }
    
    /// The type used for the completion handler result from the `start()` method
    /// - Parameters:
    ///   - context: The `IDXClient.Context` object created when the session was initiated.
    ///   - response: The `IDXClient.Response` object that describes the next workflow steps.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias StartResult = (_ context: Context?, _ response: Response?, _ error: Error?) -> Void
    
    /// The type used for the completion handler result from the `interact()` method.
    /// - Parameters:
    ///   - context: The `IDXClient.Context` object created when the session was initiated.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias ContextResult = (_ context: Context?, _ error: Error?) -> Void
    
    /// The type used for the completion  handler result from any method that returns an `IDXClient.Response`.
    /// - Parameters:
    ///   - response: The `IDXClient.Response` object that describes the next workflow steps.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias ResponseResult = (_ response: Response?, _ error: Error?) -> Void
    
    /// The type used for the completion  handler result from any method that returns an `IDXClient.Token`.
    /// - Parameters:
    ///   - token: The `IDXClient.Token` object created when the token is successfully exchanged.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias TokenResult = (_ token: Token?, _ error: Error?) -> Void

    /// Configuration used to create the IDX client.
    @objc public let configuration: Configuration
    
    /// The current context for the authentication session.
    ///
    /// This value will be populated in the following circumstances:
    /// * When a context value is specified when the IDXClient initializer is called.
    /// * When a valid Context object is returned when the `interact` method receives a successful response.
    ///
    /// For convenience, when calls to `introspect` or `exchangeCode` are made with a `nil` context value, they will use the value stored in this `context` property.
    @objc public internal(set) var context: Context?
    
    /// Optional delegate property, used to be informed when important events occur throughout the authentication workflow.
    @objc public weak var delegate: IDXClientDelegate? = nil
    
    /// Initializes an IDX client instance with the given configuration object.
    /// - Parameters:
    ///   - configuration: Configuration object describing the application.
    ///   - context: Context object to use when resuming a session.
    ///   - version: The API version to use, or `latest` if not supplied.
    ///   - queue: The DispatchQueue to send responses on, defaults to `DispatchQueue.main`.
    @objc public convenience init(configuration: Configuration,
                                  context: Context? = nil,
                                  version: Version = Version.latest,
                                  queue: DispatchQueue = DispatchQueue.main)
    {
        self.init(configuration: configuration,
                  context: context,
                  api: version.clientImplementation(with: configuration),
                  queue: queue)
    }
    
    /// Initiates the authentication workflow.
    ///
    /// This is a convenience method that wraps the `interact` and `introspect` API calls, since for the majority of scenarios a developer would not need to explicitly call one or the other.
    /// - Parameter completion: Invoked when a context and response are received, or if an error occurs.
    @objc public func start(completion: StartResult?) {
        interact { (context, error) in
            guard error == nil else {
                completion?(nil, nil, error)
                return
            }
            
            guard let context = context else {
                completion?(nil, nil, IDXClientError.missingRequiredParameter(name: "context"))
                return
            }
            
            self.introspect(context) { (response, error) in
                completion?(context, response, error)
            }
        }
    }
    
    /// Performs a request to interact with IDX, based on configured client options.
    /// - Parameters:
    ///   - completion: Invoked when a response, or error, is received.
    ///   - context: An object describing the context of the IDX interaction, or `nil` if the client configuration was invalid.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func interact(completion: ContextResult?) {
        api.interact { (context, error) in
            self.context = context
            self.handleResponse(context, error: error, completion: completion)
        }
    }
    
    /// Introspects the authentication state to identify the available remediation steps.
    ///
    /// Once an interaction handle is received, this method can be used to determine what remedation options are available to the user to authenticate.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - context: `IDXClient.Context` object that contains a valid interactionHandle, or `nil` to use the value in the IDXClient.
    ///   - completion: Optional completion handler invoked when a response is received.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func introspect(_ context: Context? = nil,
                                 completion: ResponseResult?)
    {
        guard let context = context ?? self.context else {
            handleResponse(nil,
                           error: IDXClientError.missingRequiredParameter(name: "context"),
                           completion: completion)
            return
        }
        
        api.introspect(context) { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    /// Indicates whether or not the current stage in the workflow can be cancelled.
    @objc public var canCancel: Bool {
        return api.canCancel
    }
    
    /// Cancels and restarts the current workflow.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` method to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Invoked when the operation is cancelled.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func cancel(completion: ResponseResult?) {
        api.cancel { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    /// Proceeds to the given remediation option.
    /// - Parameters:
    ///   - option: Remediation option to proceed to.
    ///   - data: Data to supply to the remediation step.
    ///   - completion: Invoked when a response, or error, is received.
    ///   - response: The response describing the next steps available in this workflow.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func proceed(remediation option: Remediation.Option,
                              data: [String : Any] = [:],
                              completion: ResponseResult?)
    {
        api.proceed(remediation: option, data: data) { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    /// Exchanges the successful response with a token.
    ///
    /// Once the `IDXClient.Response.isLoginSuccessful` property is `true`, the developer can exchange that response for a valid token by using this method.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didExchangeToken:)` method to receive the token or to handle any errors.
    /// - Parameters:
    ///   - context: `IDXClient.Context` value returned from `interact`, or `nil` to use the value stored in the IDXClient.
    ///   - response: Successful response.
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    ///   - token: The token that was exchanged, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func exchangeCode(with context: Context? = nil,
                                   using response: Response,
                                   completion: TokenResult?)
    {
        guard let context = context ?? self.context else {
            handleResponse(nil,
                           error: IDXClientError.missingRequiredParameter(name: "context"),
                           completion: completion)
            return
        }
        
        api.exchangeCode(with: context, using: response) { (token, error) in
            self.handleResponse(token, error: error, completion: completion)
        }
    }

    internal let api: IDXClientAPIImpl
    internal let queue: DispatchQueue
    internal required init(configuration: Configuration,
                           context: Context?,
                           api: IDXClientAPIImpl,
                           queue: DispatchQueue)
    {
        self.configuration = configuration
        self.context = context
        self.api = api
        self.queue = queue

        super.init()

        self.api.client = self
    }
}

/// Delegate protocol that can be used to receive updates from the IDXClient through the process of a user's authentication.
@objc
public protocol IDXClientDelegate {
    /// Message sent when an error is received at any point during the authentication process.
    /// - Parameters:
    ///   - client: IDXClient sending the error.
    ///   - error: The error that was received.
    @objc(idxClient:didReceiveError:)
    func idx(client: IDXClient, didReceive error: Error)
    
    /// Message sent when an IDX context object is returned from `interact`.
    /// - Parameters:
    ///   - client: IDXClient sending the response.
    ///   - context: The context that was received.
    @objc(idxClient:didReceiveContext:)
    func idx(client: IDXClient, didReceive context: IDXClient.Context)
    
    /// Informs the delegate when an IDX response is received, either through an `introspect` or `proceed` call.
    /// - Parameters:
    ///   - client: IDXClient receiving the response.
    ///   - response: The response that was received.
    @objc(idxClient:didReceiveResponse:)
    func idx(client: IDXClient, didReceive response: IDXClient.Response)
    
    /// Informs the delegate when authentication is successful, and the token is returned.
    /// - Parameters:
    ///   - client: IDXClient receiving the token.
    ///   - token: The IDX token object describing the user's credentials.
    @objc func idx(client: IDXClient, didExchangeToken token: IDXClient.Token)
}

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
