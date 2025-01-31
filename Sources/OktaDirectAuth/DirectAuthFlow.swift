//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Delegate protocol used by ``DirectAuthenticationFlow``.
///
/// This extends the parent protocol `AuthenticationDelegate`.
public protocol DirectAuthenticationFlowDelegate: AuthenticationDelegate {
    /// Sent when an authentication session receives a new status response.
    ///
    /// This function is invoked when a new status is returned either from ``DirectAuthenticationFlow/start(_:with:)`` or ``DirectAuthenticationFlow/resume(_:with:)`` (or their block-based counterparts).
    func authentication<Flow>(flow: Flow, received status: DirectAuthenticationFlow.Status)
}

/// Errors that may be generated while authenticating using ``DirectAuthenticationFlow``.
public enum DirectAuthenticationFlowError: Error {
    /// When polling for a background authenticator, this error may be thrown if polling for an out-of-band verification takes too long.
    case pollingTimeoutExceeded
    
    /// An authentication factor expects a "binding code" but it isn't present.
    ///
    /// For more information, please see the [related documentation](https://developer.okta.com/docs/guides/configure-direct-auth-grants/dmfaoobov/main/).
    case bindingCodeMissing
    
    /// The context supplied with the authenticator continuation request is invalid.
    case invalidContinuationContext
    
    /// An operation was attempted to be performed on a flow that was not yet started.
    case flowNotStarted
    
    /// The flow has gotten into an inconsistent state, possibly due to concurrent authentication operations being performed.
    case inconsistentContextState
    
    /// Some authenticators require specific arguments to be supplied, but are missing in this case.
    case missingArguments(_ names: [String])
    
    /// An underlying network error has occurred.
    case network(error: APIClientError)
    
    /// An OAuth2 error has been returned.
    case oauth2(error: OAuth2Error)
    
    /// An OAuth2 server error has been returned.
    case server(error: OAuth2ServerError)
    
    /// Some other unknown error has been returned.
    case other(error: Error)
}

/// An authentication flow that implements the Okta Direct Authentication API.
///
/// This enables developers to build native sign-in workflows into their applications, while leveraging MFA to securely authenticate users, without the need to present a browser. Furthermore, this enables passwordless authentication scenarios by giving developers the power to choose which primary and secondary authentication factors to use when challenging a user for their credentials.
public class DirectAuthenticationFlow: AuthenticationFlow {
    /// Enumeration defining the list of possible primary authentication factors.
    ///
    /// These values are used by the ``DirectAuthenticationFlow/start(_:with:)`` function.
    public enum PrimaryFactor: Equatable {
        /// Authenticate the user with the given password.
        ///
        /// This is used when supplying a password as a primary factor. For example:
        ///
        /// ```swift
        /// let status = try await flow.start("jane.doe@example.com", with: .password("SuperSecret"))
        /// ```
        case password(String)
        
        /// Authenticate the user with the given OTP code.
        ///
        /// This usually represents app authenticators such as Google Authenticator, and can be supplied along with a user identifier. For example:
        ///
        /// ```swift
        /// let status = try await flow.start("jane.doe@example.com", with: .otp("123456"))
        /// ```
        case otp(code: String)
        
        /// Authenticate the user out-of-band using Okta Verify.
        ///
        /// This is used along with a user identifier to perform a passwordless sign in using Okta Verify. For example:
        ///
        /// ```swift
        /// let status = try await flow.start("jane.doe@example.com", with: .push)
        /// ```
        ///
        /// > Note: While `.oob` accepts a `channel` argument, at this time only the `push` option is available.
        case oob(channel: OOBChannel = .push)
        
        /// Authenticate the user using WebAuthn.
        ///
        /// This requests that a new WebAuthn challenge is generated and returned to the client, which can subsequently be used to sign the attestation for return back to the server.
        ///
        /// ```swift
        /// let status = try await flow.start("jane.doe@example.com", with: .webAuthn)
        /// ```
        case webAuthn
    }
    
    /// Enumeration defining the list of possible secondary authentication factors.
    ///
    /// These values are used by ``DirectAuthenticationFlow/resume(_:with:)``.
    public enum SecondaryFactor: Equatable {
        /// Authenticate the user with the given OTP code.
        ///
        /// This usually represents app authenticators such as Google Authenticator, and can be supplied along with a user identifier. For example:
        ///
        /// ```swift
        /// let newStatus = try await flow.resume(status, with: .otp("123456"))
        /// ```
        case otp(code: String)
        
        /// Authenticate the user out-of-band using Okta Verify.
        ///
        /// ```swift
        /// let newStatus = try await flow.resume(status, with: .push)
        /// ```
        ///
        /// > Note: While `.oob` accepts a `channel` argument, at this time only the `push` option is available.
        case oob(channel: OOBChannel)
        
        /// Authenticate the user using WebAuthn.
        ///
        /// This requests that a new WebAuthn challenge is generated and returned to the client, which can subsequently be used to sign the attestation for return back to the server.
        ///
        /// ```swift
        /// let status = try await flow.resume(status, with: .webAuthn)
        /// ```
        case webAuthn
    }
    
    /// Enumeration defining the list of possible authenticator "Continuation" factors, which are used.
    ///
    /// Some authenticators cannot complete authentication in a single step, and requires either user intervention or an additional challenge response from the client. These circumstances are represented by the ``DirectAuthenticationFlow/Status/continuation(_:)`` status. In this case, the appropriate Continuation Factor response type can be supplied to the ``DirectAuthenticationFlow/resume(with:)-9gu1l`` function.
    public enum ContinuationFactor: Equatable {
        /// Continues an OOB authentication by transfering the binding to another authenticator, and waiting for its response.
        ///
        /// For example, if an Okta Verify number challenge needs to be presented to the user (also referred to as a "Binding Transfer"), the OOB authentication can be continued.
        ///
        /// ```
        /// if case let .continuation(type) = status,
        ///    case let .transfer(_, code: code) = type
        /// {
        ///     // Present the code to the user
        ///     status = try await flow.resume(status, with: .transfer)
        /// }
        /// ```
        case transfer
        
        /// Respond to an OOB authentication where a code is supplied to a second channel, which will be supplied here.
        ///
        /// This is used when some code needs to be supplied by the user in response to an out-of-band authentication, for example when authenticating using an SMS phone factor.
        ///
        /// ```
        /// var status = try await flow.start("jane.doe@example.com", with: .oob(channel: .sms)
        /// if case let .continuation(type) = status,
        ///    case let .prompt(_) = type
        /// {
        ///    // Prompt the user to input the code
        ///    let verificationCode = await getCodeFromUser()
        ///
        ///    let newStatus = try await flow.resume(status, with: .prompt(verificationCode))
        /// }
        /// ```
        case prompt(code: String)
        
        /// Respond to a WebAuthn challenge with an authenticator assertion.
        ///
        /// This uses a previously supplied WebAuthn challenge (using ``DirectAuthenticationFlow/PrimaryFactor/webAuthn`` or ``DirectAuthenticationFlow/SecondaryFactor/webAuthn``) to respond to the server with the signed attestation from the local authenticator.
        case webAuthn(response: WebAuthn.AuthenticatorAssertionResponse)
    }
    
    /// Configuration which can be used to customize the authentication flow, as needed.
    public struct Context: AuthenticationContext, Equatable {
        /// The ACR values, if any, which should be requested by the client.
        public var acrValues: [String]?

        /// The intent of the current flow.
        public var intent: Intent = .signIn
        
        /// The current status returned from this authentication flow.
        public internal(set) var currentStatus: Status?

        public init(maxAge: TimeInterval? = nil,
                    acrValues: [String]? = nil,
                    intent: Intent = .signIn)
        {
            self.init(acrValues: acrValues,
                      intent: intent)
        }

        init(acrValues: [String]?,
             intent: Intent)
        {
            self.acrValues = acrValues
            self.intent = intent
        }

        @_documentation(visibility: internal)
        public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
            var result: [String: any APIRequestArgument] = [:]
            
            if let acrValues = acrValues {
                result["acr_values"] = acrValues.joined(separator: " ")
            }
            
            if category == .token {
                result.merge(intent.parameters(for: category))
            }
            
            return result.nilIfEmpty
        }
    }
    
    /// Channel used when authenticating an out-of-band factor using Okta Verify.
    public enum OOBChannel: String, Codable, Equatable, APIRequestArgument {
        /// Utilize Okta Verify Push notifications to authenticate the user.
        case push
        
        /// Receive a phone verification code via SMS.
        case sms
        
        /// Receive a phone verification code via a voice call.
        case voice
    }
    
    /// Context information used to define a request from the server to perform a multifactor authentication.
    ///
    /// This is largely used internally to ensure the secondary factor is linked to the user's current authentication session, but can be used to see the list of challenge types that are supported.
    public struct MFAContext: Equatable {
        /// The list of possible grant types that the user can be challenged with.
        public let supportedChallengeTypes: [GrantType]?
        let mfaToken: String
        
        public init(supportedChallengeTypes: [GrantType]?, mfaToken: String) {
            self.supportedChallengeTypes = supportedChallengeTypes
            self.mfaToken = mfaToken
        }
    }
    
    /// The current status of the authentication flow.
    ///
    /// This value is returned from ``DirectAuthenticationFlow/start(_:with:)`` and ``DirectAuthenticationFlow/resume(with:)`` to indicate the result of an individual authentication step. This can be used to drive your application's sign-in workflow.
    public enum Status: Equatable {
        /// Authentication was successful, returning the given token.
        case success(_ token: Token)
        
        /// Indicates that the current authentication factor requires some sort of continuation.
        ///
        /// When this status is returned, the developer should inspect the type of continuation that is occurring, and should use the ``DirectAuthenticationFlow/resume(with:)-9gu1l`` function to resume authenticating this factor.
        case continuation(_ type: ContinuationType)
        
        /// Indicates the user should be challenged with some other secondary factor.
        ///
        /// When this status is returned, the developer should use the ``DirectAuthenticationFlow/resume(with:)`` function to supply a secondary factor to verify the user.
        case mfaRequired(_ context: MFAContext)
    }
    
    /// The type of authentication continuation that is requested.
    ///
    /// Some authenticators follow a challenge and response pattern, whereby the client either needs to prompt the user for some out-of-band information, or the client needs to respond directly to a challenge sent from the server. When these situations occur, this enum can be used to determine which action should be taken by the client.
    public enum ContinuationType: Equatable {
        /// Indicates the user is being prompted with a WebAuthn challenge request.
        case webAuthn(_ context: WebAuthnContext)
        
        /// Indicates that there is an update about binding authentication channels when verifying OOB factors.
        case transfer(_ context: BindingContext, code: String)
        
        /// Indicates that the authenticator will prompt the user for a code, will occur through a secondary channel, such as SMS phone verification.
        case prompt(_ context: BindingContext)
        
        /// Holds information about a challenge request when initiating a WebAuthn authentication.
        public struct WebAuthnContext: Equatable {
            /// The credential request returned from the server.
            public let request: WebAuthn.CredentialRequestOptions
            
            let mfaContext: MFAContext?
        }
        
        /// Holds information about the binding update received when verifying OOB factors
        public struct BindingContext: Equatable {
            let oobResponse: OOBResponse
            let mfaContext: MFAContext?
        }
    }
    
    /// Indicates the intent for the user authentication operation.
    ///
    /// This value is used to toggle behavior to distinguish between sign-in authentication, password recovery / reset operations, etc.
    public enum Intent: String, Codable, Equatable {
        /// The user intends to sign in.
        case signIn
        
        /// The user intends to recover / reset their password, or some other authentication factor.
        case recovery
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The list of grant types the application supports.
    public let supportedGrantTypes: [GrantType]

    /// The context that stores the state for the current authentication session.
    public internal(set) var context: Context? {
        didSet {
            print("Reset context")
        }
    }

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    public let additionalParameters: [String: APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    public private(set) var isAuthenticating: Bool = false {
        didSet {
            guard oldValue != isAuthenticating else {
                return
            }
            
            if isAuthenticating {
                delegateCollection.invoke { $0.authenticationStarted(flow: self) }
            } else {
                delegateCollection.invoke { $0.authenticationFinished(flow: self) }
            }
        }
    }
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID
    ///   - scope: The scopes to request
    ///   - grantTypes: The supported list of grant types the application has been configured to use
    ///   - additionalParameters: Custom request parameters to be added to requests made for this sign-in.
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: String,
                            supportedGrants grantTypes: [GrantType] = .directAuth,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(client: .init(issuerURL: issuerURL,
                                clientId: clientId,
                                scope: scope),
                  supportedGrants: grantTypes,
                  additionalParameters: additionalParameters)
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - grantTypes: The supported list of grant types the application has been configured to use
    ///   - additionalParameters: Custom request parameters to be added to requests made for this sign-in.
    public init(client: OAuth2Client,
                supportedGrants grantTypes: [GrantType] = .directAuth,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.supportedGrantTypes = grantTypes
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    public required init(client: OAuth2Client, additionalParameters: [String: any APIRequestArgument]?) throws {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.supportedGrantTypes = .directAuth
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }

    /// Start user authentication, with the given username login hint and primary factor.
    /// - Parameters:
    ///   - loginHint: The login hint, or username, to authenticate.
    ///   - factor: The primary factor to use when authenticating the user.
    ///   - context: Context information used to customize the sign-in flow.
    ///   - completion: Completion block called when the operation completes.
    public func start(_ loginHint: String,
                      with factor: PrimaryFactor,
                      context: Context = .init(),
                      completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        reset()
        self.context = context
        runStep(loginHint: loginHint, with: factor, completion: completion)
    }
    
    /// Resumes authentication when an additional (secondary) factor is required to verify the user.
    ///
    /// This function should be used when ``Status/mfaRequired(_:)`` is received.
    /// - Parameters:
    ///   - factor: The secondary factor to use when authenticating the user.
    ///   - completion: Completion block called when the operation completes.
    public func resume(with factor: SecondaryFactor,
                       completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        guard isAuthenticating,
              context != nil
        else {
            completion(.failure(.flowNotStarted))
            return
        }
        
        runStep(with: factor, completion: completion)
    }

    /// Continues authentication of a current factor (either primary or secondary) when an additional step is required.
    ///
    /// This function should be used when ``Status/continuation(_:)`` is received.
    /// - Parameters:
    ///   - factor: The continuation factor to use when authenticating the user.
    ///   - completion: Completion block called when the operation completes.
    public func resume(with factor: ContinuationFactor,
                       completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        guard context != nil else {
            completion(.failure(.flowNotStarted))
            return
        }
        
        runStep(with: factor, completion: completion)
    }
    
    func runStep<Factor: AuthenticationFactor>(loginHint: String? = nil,
                                               with factor: Factor,
                                               completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void)
    {
        isAuthenticating = true
        
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let stepHandler: any StepHandler
                do {
                    stepHandler = try factor.stepHandler(flow: self,
                                                         openIdConfiguration: configuration,
                                                         loginHint: loginHint,
                                                         factor: factor)
                } catch {
                    self.send(error: error, completion: completion)
                    return
                }

                self.process(stepHandler, completion: completion)

            case .failure(let error):
                self.send(error: error, completion: completion)
            }
        }
    }
    
    func process(_ stepHandler: any StepHandler, completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void) {
        guard let oldContext = context else {
            completion(.failure(.inconsistentContextState))
            return
        }
        
        stepHandler.process { result in
            guard self.context == oldContext else {
                self.send(error: DirectAuthenticationFlowError.inconsistentContextState,
                          completion: completion)
                return
            }
            
            if case let .success(newStatus) = result {
                var newContext = oldContext
                newContext.currentStatus = newStatus
                self.context = newContext
            }
            
            completion(result)
        }
    }
    
    /// Resets the authentication session.
    public func reset() {
        isAuthenticating = false
        context = nil
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<DirectAuthenticationFlowDelegate>()
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension DirectAuthenticationFlow {
    /// Start user authentication, with the given username login hint and primary factor.
    /// - Parameters:
    ///   - loginHint: The login hint, or username, to authenticate.
    ///   - factor: The primary factor to use when authenticating the user.
    ///   - context: Context information used to customize the sign-in flow.
    /// - Returns: Status returned when the operation completes.
    public func start(_ loginHint: String,
                      with factor: PrimaryFactor,
                      context: Context = .init()) async throws -> DirectAuthenticationFlow.Status
    {
        try await withCheckedThrowingContinuation { continuation in
            start(loginHint, with: factor, context: context) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Resumes authentication when an additional (secondary) factor is required to verify the user.
    ///
    /// This function should be used when ``Status/mfaRequired(_:)`` is received.
    /// - Parameters:
    ///   - factor: The secondary factor to use when authenticating the user.
    /// - Returns: Status returned when the operation completes.
    public func resume(with factor: SecondaryFactor) async throws -> DirectAuthenticationFlow.Status {
        try await withCheckedThrowingContinuation { continuation in
            resume(with: factor) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Continues authentication of a current factor (either primary or secondary) when an additional step is required.
    ///
    /// This function should be used when ``Status/continuation(_:)`` is received.
    /// - Parameters:
    ///   - factor: The continuation factor to use when authenticating the user.
    /// - Returns: Status returned when the operation completes.
    public func resume(with factor: ContinuationFactor) async throws -> DirectAuthenticationFlow.Status {
        try await withCheckedThrowingContinuation { continuation in
            resume(with: factor) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension DirectAuthenticationFlow: UsesDelegateCollection {
    public typealias Delegate = DirectAuthenticationFlowDelegate
}

extension DirectAuthenticationFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    /// Creates a new flow to authenticate users, with the given grants the application supports.
    /// - Parameters:
    ///   - grantTypes: The supported list of grant types the application has been configured to use
    ///   - additionalParameters: Custom request parameters to be added to requests made for this sign-in.
    /// - Returns: Initialized authentication flow.
    public func directAuthenticationFlow(supportedGrants grantTypes: [GrantType] = .directAuth,
                                         additionalParameters: [String: String]? = nil) -> DirectAuthenticationFlow
    {
        DirectAuthenticationFlow(client: self,
                                 supportedGrants: grantTypes,
                                 additionalParameters: additionalParameters)
    }
}
