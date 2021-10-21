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

/// Protocol authenticators may conform to if they are capable of the "send" action.
///
/// This is often used in Phone authenticators.
public protocol Sendable: AnyObject {
    /// Determines if this action can perform the send action.
    var canSend: Bool { get }
    
    /// Sends the authentication code.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    func send(completion: IDXClient.ResponseResult?)

    /// Sends the authentication code.
    /// - Parameter completion: Completion handler when the response is returned, or `nil` if the developer does not need to handle the response.
    func send(completion: IDXClient.ResponseResultCallback?)
}

/// Protocol authenticators may conform to if they are capable of the "resend" action.
///
/// This is typically used by Email and Phone authenticators.
public protocol Resendable: AnyObject {
    /// Determines if this action can perform the resend action.
    var canResend: Bool { get }

    /// Resends a new authentication code.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    func resend(completion: IDXClient.ResponseResult?)

    /// Resends a new authentication code.
    /// - Parameter completion: Completion handler when the response is returned, or `nil` if the developer does not need to handle the response.
    func resend(completion: IDXClient.ResponseResultCallback?)
}

/// Protocol authenticators may conform to if they can be used to recover an account.
public protocol Recoverable: AnyObject {
    /// Determines if this action can perform the recover action.
    var canRecover: Bool { get }

    /// Requests that the recovery code is sent.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    func recover(completion: IDXClient.ResponseResult?)

    /// Requests that the recovery code is sent.
    /// - Parameter completion: Completion handler when the response is returned, or `nil` if the developer does not need to handle the response.
    func recover(completion: IDXClient.ResponseResultCallback?)
}

/// Protocol authenticators can conform to if they can be polled to determine out-of-band actions taken by the user.
public protocol Pollable: AnyObject {
    /// Determines if this authenticator can be polled.
    var canPoll: Bool { get }
    
    /// Indicates whether or not this authenticator is actively polling.
    var isPolling: Bool { get }
    
    /// Starts the polling process.
    ///
    /// The action will be continually polled in the background either until `stopPolling` is called, or when the authenticator has finished. The completion block is invoked once the user has completed the action out-of-band, or when an error is received.
    /// - Parameter completion: Completion handler when the polling is complete, or `nil` if the developer does not need to handle the response
    func startPolling(completion: IDXClient.ResponseResult?)
    
    /// Starts the polling process.
    ///
    /// The action will be continually polled in the background either until `stopPolling` is called, or when the authenticator has finished. The completion block is invoked once the user has completed the action out-of-band, or when an error is received.
    /// - Parameter completion: Completion handler when the polling is complete with the result of the operation.
    func startPolling(completion: IDXClient.ResponseResultCallback?)

    /// Stops the polling process from continuing.
    func stopPolling()
}

/// Protocol authenticators conform to when they can contain profile information related to the authenticator.
public protocol HasProfile: AnyObject {
    /// Profile information describing the authenticator. This usually contains redacted information relevant to display to the user.
    var profile: [String:String]? { get }
}

extension IDXClient {
    /// Represents information describing the available authenticators and enrolled authenticators.
    @objc(IDXAuthenticator)
    public class Authenticator: NSObject {
        /// Unique identifier for this enrollment
        @objc(identifier)
        public let id: String?

        /// The user-visible name to use for this authenticator enrollment.
        @objc public let displayName: String?

        /// The type of this authenticator, or `unknown` if the type isn't represented by this enumeration.
        @objc public let type: Kind
        
        /// The key name for the authenticator
        @objc public let key: String?
        
        /// Indicates the state of this authenticator, either being an available authenticator, an enrolled authenticator, authenticating, or enrolling.
        @objc public let state: State

        /// Describes the various methods this authenticator can perform.
        @nonobjc public let methods: [Method]?
        
        /// Describes the various methods this authenticator can perform, as string values.
        @objc public let methodNames: [String]?
        
        // TODO: deviceKnown?
        // TODO: credentialId?
        
//        /// Data that is relevant within the context of this authenticator, such as security questions or WebAuthN.
//        @objc public let contextualData: Any?

        private weak var client: IDXClientAPI?
        let jsonPaths: [String]
        init(client: IDXClientAPI,
             v1JsonPaths: [String],
             state: State,
             id: String?,
             displayName: String?,
             type: String,
             key: String?,
             methods: [[String:String]]?)
        {
            self.client = client
            self.jsonPaths = v1JsonPaths
            self.state = state
            self.id = id
            self.displayName = displayName
            self.type = Kind(string: type)
            self.key = key
            self.methods = methods?.compactMap {
                guard let type = $0["type"] else { return nil }
                return Method(string: type)
            }
            self.methodNames = methods?.compactMap { $0["type"] }

            super.init()
        }
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [
                logger.address(),
                "\(#keyPath(type)): \(type.rawValue)",
                "\(#keyPath(state)): \(state.rawValue)",
            ]
            
            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            let components = [
                "\(#keyPath(id)): \(id ?? "-")",
                "\(#keyPath(displayName)): \(displayName ?? "-")",
                "\(#keyPath(key)): \(key ?? "-")",
                "\(#keyPath(methodNames)): \(methodNames ?? [])"
            ]
            
            return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
        }
        
        /// Describes a password authenticator.
        @objc(IDXPasswordAuthenticator)
        public class Password: Authenticator, Recoverable {
            /// Provides details about the password complexity settings for this authenticator.
            @objc public let settings: Settings?
            
            @objc public var canRecover: Bool { recoverOption != nil }
            
            @objc public func recover(completion: IDXClient.ResponseResultCallback?) {
                recover { result in
                    switch result {
                    case .failure(let error):
                        completion?(nil, error)
                    case .success(let response):
                        completion?(response, nil)
                    }
                }
            }
            
            public func recover(completion: IDXClient.ResponseResult? = nil) {
                guard let client = client else {
                    completion?(.failure(.invalidClient))
                    return
                }
                
                guard let recoverOption = recoverOption else {
                    completion?(.failure(.missingRemediationOption(name: "recover")))
                    return
                }
                
                client.proceed(remediation: recoverOption, completion: completion)
            }
            
            @objc(IDXPasswordSettings)
            public class Settings: NSObject {
                @objc public let daysToExpiry: Int
                @objc public let minLength: Int
                @objc public let minLowerCase: Int
                @objc public let minUpperCase: Int
                @objc public let minNumber: Int
                @objc public let minSymbol: Int
                @objc public let excludeUsername: Bool
                @objc public let excludeAttributes: [String]
                
                init(daysToExpiry: Int,
                     minLength: Int,
                     minLowerCase: Int,
                     minUpperCase: Int,
                     minNumber: Int,
                     minSymbol: Int,
                     excludeUsername: Bool,
                     excludeAttributes: [String])
                {
                    self.daysToExpiry = daysToExpiry
                    self.minLength = minLength
                    self.minLowerCase = minLowerCase
                    self.minUpperCase = minUpperCase
                    self.minNumber = minNumber
                    self.minSymbol = minSymbol
                    self.excludeUsername = excludeUsername
                    self.excludeAttributes = excludeAttributes

                    super.init()
                }
                
                public override var description: String {
                    let logger = DebugDescription(self)
                    let components = [logger.address()]

                    return logger.brace(components.joined(separator: "; "))
                }
                
                public override var debugDescription: String {
                    let components = [
                        "\(#keyPath(daysToExpiry)): \(daysToExpiry)",
                        "\(#keyPath(minLength)): \(minLength)",
                        "\(#keyPath(minLowerCase)): \(minLowerCase)",
                        "\(#keyPath(minUpperCase)): \(minUpperCase)",
                        "\(#keyPath(minNumber)): \(minNumber)",
                        "\(#keyPath(minSymbol)): \(minSymbol)",
                        "\(#keyPath(excludeUsername)): \(excludeUsername)",
                        "\(#keyPath(excludeAttributes)): \(excludeAttributes)",
                    ]

                    return """
                    \(description) {
                    \(DebugDescription(self).format(components, indent: 4))
                    }
                    """
                }
            }
            
            internal let recoverOption: IDXClient.Remediation?
            
            internal init(client: IDXClientAPI,
                          v1JsonPaths: [String],
                          state: State,
                          id: String?,
                          displayName: String?,
                          type: String,
                          key: String?,
                          methods: [[String:String]]?,
                          settings: Settings?,
                          recoverOption: IDXClient.Remediation?)
            {
                self.settings = settings
                self.recoverOption = recoverOption

                super.init(client: client,
                           v1JsonPaths: v1JsonPaths,
                           state: state,
                           id: id,
                           displayName: displayName,
                           type: type,
                           key: key,
                           methods: methods)
            }
            
            public override var description: String {
                let logger = DebugDescription(self)
                let components = [
                    logger.address(),
                    "\(#keyPath(canRecover)): \(canRecover)"
                ]

                return logger.brace(components.joined(separator: "; "))
            }
            
            public override var debugDescription: String {
                let components = [settings?.debugDescription ?? "-"]
                
                return """
                \(super.debugDescription.replacingOccurrences(of: "\n}", with: ""))
                \(DebugDescription(self).format(components, indent: 4))
                }
                """
            }
        }

        /// Base class that several authenticators are built upon.
        @objc(IDXProfileBaseAuthenticator)
        public class ProfileAuthenticator: Authenticator, HasProfile {
            @objc public let profile: [String:String]?
            
            internal init(client: IDXClientAPI,
                          v1JsonPaths: [String],
                          state: State,
                          id: String?,
                          displayName: String?,
                          type: String,
                          key: String?,
                          methods: [[String:String]]?,
                          profile: [String:String]?)
            {
                self.profile = profile

                super.init(client: client,
                           v1JsonPaths: v1JsonPaths,
                           state: state,
                           id: id,
                           displayName: displayName,
                           type: type,
                           key: key,
                           methods: methods)
            }
            
            public override var debugDescription: String {
                let components = [
                    "\(#keyPath(profile)): \(profile?.debugDescription ?? "-")"
                ]
                
                return """
                \(super.debugDescription.replacingOccurrences(of: "\n}", with: ""))
                \(DebugDescription(self).format(components, indent: 4))
                }
                """
            }
        }
        
        /// Email authenticator, used to authenticate a user based on their email address.
        @objc(IDXEmailAuthenticator)
        public class Email: ProfileAuthenticator, Resendable, Pollable {
            /// Convenience method to return the redacted email address associated with this user.
            @objc public var emailAddress: String? { profile?["email"] }
            @objc public var isPolling: Bool { pollHandler?.isPolling ?? false }
            @objc public var refreshTime: TimeInterval { pollOption?.refresh ?? 0 }
            @objc public var canResend: Bool { resendOption != nil }
            @objc public var canPoll: Bool { pollOption != nil }

            public func startPolling(completion: IDXClient.ResponseResult? = nil) {
                // Stop any previous polling
                stopPolling()
                
                let handler = PollingHandler()
                handler.delegate = self
                handler.start { [weak self] (response, error) in
                    guard let response = response else {
                        if let error = error {
                            completion?(.failure(.internalError(error)))
                        } else {
                            completion?(.failure(.invalidResponseData))
                        }
                        return false
                    }
                    
                    // If we don't get another email authenticator back, we know the
                    // magic link was clicked, and we can proceed to the completion block.
                    guard let emailAuthenticator = response.authenticators.current as? Email else {
                        completion?(.success(response))
                        return false
                    }
                    
                    self?.pollOption = emailAuthenticator.pollOption
                    return true
                }
                pollHandler = handler
            }
            
            @objc public func startPolling(completion: IDXClient.ResponseResultCallback?) {
                startPolling { result in
                    switch result {
                    case .failure(let error):
                        completion?(nil, error)
                    case .success(let response):
                        completion?(response, nil)
                    }
                }
            }

            @objc public func stopPolling() {
                pollHandler?.stopPolling()
                pollHandler = nil
            }
            
            public func resend(completion: IDXClient.ResponseResult? = nil) {
                guard let client = client else {
                    completion?(.failure(.invalidClient))
                    return
                }
                
                guard let resendOption = resendOption else {
                    completion?(.failure(.missingRemediationOption(name: "resend"))) // TODO: Send error
                    return
                }
                
                client.proceed(remediation: resendOption, completion: completion)
            }
            
            @objc public func resend(completion: IDXClient.ResponseResultCallback?) {
                resend { result in
                    switch result {
                    case .failure(let error):
                        completion?(nil, error)
                    case .success(let response):
                        completion?(response, nil)
                    }
                }
            }

            internal let resendOption: IDXClient.Remediation?
            internal private(set) var pollOption: IDXClient.Remediation?
            private var pollHandler: PollingHandler?
            
            internal init(client: IDXClientAPI,
                          v1JsonPaths: [String],
                          state: State,
                          id: String?,
                          displayName: String?,
                          type: String,
                          key: String?,
                          methods: [[String:String]]?,
                          profile: [String:String]?,
                          resendOption: IDXClient.Remediation?,
                          pollOption: IDXClient.Remediation?)
            {
                self.resendOption = resendOption
                self.pollOption = pollOption

                super.init(client: client,
                           v1JsonPaths: v1JsonPaths,
                           state: state,
                           id: id,
                           displayName: displayName,
                           type: type,
                           key: key,
                           methods: methods,
                           profile: profile)
            }
            
            public override var debugDescription: String {
                let components = [
                    "\(#keyPath(emailAddress)): \(emailAddress ?? "-")",
                    "\(#keyPath(isPolling)): \(isPolling)",
                    "\(#keyPath(canResend)): \(canResend)",
                    "\(#keyPath(canPoll)): \(canPoll)",
                    "\(#keyPath(profile)): \(profile?.debugDescription ?? "-")"
                ]
                
                return """
                \(super.debugDescription.replacingOccurrences(of: "\n}", with: ""))
                \(DebugDescription(self).format(components, indent: 4))
                }
                """
            }
        }

        /// Authenticator that utilizes a user's phone to authenticate them, either by sending an SMS or voice message.
        @objc(IDXPhoneAuthenticator)
        public class Phone: ProfileAuthenticator, Sendable, Resendable {
            /// Convenience method to return the redacted phone number associated with this user.
            @objc public var phoneNumber: String? { profile?["phoneNumber"] }
            @objc public var canSend: Bool { sendOption != nil }
            @objc public var canResend: Bool { resendOption != nil }

            public func send(completion: IDXClient.ResponseResult? = nil) {
                guard let client = client else {
                    completion?(.failure(.invalidClient))
                    return
                }
                
                guard let sendOption = sendOption else {
                    completion?(.failure(.missingRemediationOption(name: "send"))) // TODO: Send error
                    return
                }
                
                client.proceed(remediation: sendOption, completion: completion)
            }
            
            @objc public func send(completion: IDXClient.ResponseResultCallback?) {
                send { result in
                    switch result {
                    case .failure(let error):
                        completion?(nil, error)
                    case .success(let response):
                        completion?(response, nil)
                    }
                }
            }
            
            public func resend(completion: IDXClient.ResponseResult? = nil) {
                guard let client = client else {
                    completion?(.failure(.invalidClient))
                    return
                }
                
                guard let resendOption = resendOption else {
                    completion?(.failure(.missingRemediationOption(name: "resend")))
                    return
                }
                
                client.proceed(remediation: resendOption, completion: completion)
            }
            
            @objc public func resend(completion: IDXClient.ResponseResultCallback?) {
                resend { result in
                    switch result {
                    case .failure(let error):
                        completion?(nil, error)
                    case .success(let response):
                        completion?(response, nil)
                    }
                }
            }

            internal let sendOption: IDXClient.Remediation?
            internal let resendOption: IDXClient.Remediation?
            internal init(client: IDXClientAPI,
                          v1JsonPaths: [String],
                          state: State,
                          id: String?,
                          displayName: String?,
                          type: String,
                          key: String?,
                          methods: [[String:String]]?,
                          profile: [String:String]?,
                          sendOption: IDXClient.Remediation?,
                          resendOption: IDXClient.Remediation?)
            {
                self.sendOption = sendOption
                self.resendOption = resendOption

                super.init(client: client,
                           v1JsonPaths: v1JsonPaths,
                           state: state,
                           id: id,
                           displayName: displayName,
                           type: type,
                           key: key,
                           methods: methods,
                           profile: profile)
            }
            
            public override var description: String {
                let logger = DebugDescription(self)
                let components = [
                    logger.address(),
                    "\(#keyPath(phoneNumber)): \(phoneNumber ?? "-")",
                    "\(#keyPath(canSend)): \(canSend)",
                    "\(#keyPath(canResend)): \(canResend)"
                ]

                return logger.brace(components.joined(separator: "; "))
            }
            
            public override var debugDescription: String {
                """
                \(super.debugDescription.replacingOccurrences(of: "\n}", with: ""))
                }
                """
            }
        }

        @objc(IDXSecurityQuestionAuthenticator)
        public class SecurityQuestion: ProfileAuthenticator {
            @objc public var question: String? { profile?["question"] }
            @objc public var questionKey: String? { profile?["question_key"] }
            
            public override var debugDescription: String {
                let components = [
                    "\(#keyPath(question)): \(question ?? "-")",
                    "\(#keyPath(questionKey)): \(questionKey ?? "-")"
                ]
                
                return """
                \(super.debugDescription.replacingOccurrences(of: "\n}", with: ""))
                \(DebugDescription(self).format(components, indent: 4))
                }
                """
            }
        }
    }
}
