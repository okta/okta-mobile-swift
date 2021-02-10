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

extension IDXClient {
    internal class APIVersion1 {
        static let version = Version.v1_0_0
        weak var client: IDXClientAPI?
        var stateHandle: String? = nil
        var interactionHandle: String? = nil
        var codeVerifier: String? = nil
        var cancelRemediationOption: IDXClient.Remediation.Option? = nil
        
        let configuration: IDXClient.Configuration
        let session: URLSessionProtocol

        init(with configuration: Configuration, session: URLSessionProtocol? = nil) {
            self.configuration = configuration
            self.session = session ?? URLSession(configuration: URLSessionConfiguration.ephemeral)
        }
    }
    
    internal func handleResponse<T>(_ response: T?, error: Error?, completion: ((T?, Error?) -> Void)?) {
        self.queue.async {
            self.informDelegate(self.delegate, response: response, error: error)
            
            completion?(response, error)
        }
    }
    
    internal func informDelegate<T>(_ delegate: IDXClientDelegate?, response: T?, error: Error?) {
        guard let delegate = delegate else { return }
        if let error = error {
            delegate.idx(client: self, didReceive: error)
        }
        
        if let response = response as? Response {
            delegate.idx(client: self, didReceive: response)
        } else if let response = response as? Token {
            delegate.idx(client: self, didExchangeToken: response)
        }
    }

    public func start(completion: ((Response?, Error?) -> Void)?) {
        interact { (context, error) in
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            guard let context = context else {
                completion?(nil, IDXClientError.missingRequiredParameter(name: "context"))
                return
            }
            
            self.introspect(context.interactionHandle, completion: completion)
        }
    }
    
    public func interact(completion: @escaping (Context?, Error?) -> Void) {
        self.api.interact { (context, error) in
            self.context = context
            self.handleResponse(context, error: error, completion: completion)
        }
    }
    
    public func introspect(_ interactionHandle: String, completion: ((Response?, Error?) -> Void)?) {
        self.api.introspect(interactionHandle) { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    public var canCancel: Bool {
        return self.api.canCancel
    }
    
    public func cancel(completion: ((Response?, Error?) -> Void)?) {
        self.api.cancel { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    public func proceed(remediation option: Remediation.Option,
                        data: [String : Any] = [:],
                        completion: ((IDXClient.Response?, Error?) -> Void)?)
    {
        self.api.proceed(remediation: option, data: data) { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }
    
    public func exchangeCode(using response: Response, completion: ((Token?, Error?) -> Void)?) {
        self.api.exchangeCode(using: response) { (token, error) in
            self.handleResponse(token, error: error, completion: completion)
        }
    }
}

extension IDXClient.Remediation.RemediationType {
    internal init(string value: String) {
        switch value {
        case "identify":                          self = .identify
        case "select-identify":                   self = .selectIdentify
        case "select-enroll-profile":             self = .selectEnrollProfile
        case "cancel":                            self = .cancel
        case "activate-factor":                   self = .activateFactor
        case "send":                              self = .sendChallenge
        case "resend":                            self = .resendChallenge
        case "select-factor-authenticate":        self = .selectFactorAuthenticate
        case "select-factor-enroll":              self = .selectFactorEnroll
        case "challenge-factor":                  self = .challengeFactor
        case "select-authenticator-authenticate": self = .selectAuthenticatorAuthenticate
        case "select-authenticator-enroll":       self = .selectAuthenticatorEnroll
        case "select-enrollment-channel":         self = .selectEnrollmentChannel
        case "authenticator-verification-data":   self = .authenticatorVerificationData
        case "authenticator-enrollment-data":     self = .authenticatorEnrollmentData
        case "enrollment-channel-data":           self = .enrollmentChannelData
        case "challenge-authenticator":           self = .challengeAuthenticator
        case "poll":                              self = .poll
        case "enroll-poll":                       self = .enrollPoll
        case "recover":                           self = .recover
        case "enroll-factor":                     self = .enrollFactor
        case "enroll-authenticator":              self = .enrollAuthenticator
        case "reenroll-authenticator":            self = .reenrollAuthenticator
        case "reenroll-authenticator-warning":    self = .reenrollAuthenticatorWarning
        case "reset-authenticator":               self = .resetAuthenticator
        case "enroll-profile":                    self = .enrollProfile
        case "profile-attributes":                self = .profileAttributes
        case "select-idp":                        self = .selectIdp
        case "select-platform":                   self = .selectPlatform
        case "factor-poll-verification":          self = .factorPollVerification
        case "qr-refresh":                        self = .qrRefresh
        case "device-challenge-poll":             self = .deviceChallengePoll
        case "cancel-polling":                    self = .cancelPolling
        case "device-apple-sso-extension":        self = .deviceAppleSsoExtension
        case "launch-authenticator":              self = .launchAuthenticator
        case "redirect":                          self = .redirect
        case "redirect-idp":                      self = .redirectIdp
        case "cancel-transaction":                self = .cancelTransaction
        case "skip":                              self = .skip
        case "challenge-poll":                    self = .challengePoll
        default:                                  self = .unknown
        }
    }
}

extension IDXClient.Authenticator.AuthenticatorType {
    internal init(string value: String) {
        switch value {
        case "app":               self = .app
        case "email":             self = .email
        case "phone":             self = .phone
        case "password":          self = .password
        case "security_question": self = .security_question
        case "device":            self = .device
        case "security_key":      self = .security_key
        case "federated":         self = .federated
        default:                  self = .unknown
        }
    }
}

extension IDXClient.Authenticator.AuthenticatorMethodType {
    internal init(string value: String) {
        switch value {
        case "sms":               self = .sms
        case "voice":             self = .voice
        case "email":             self = .email
        case "push":              self = .push
        case "crypto":            self = .crypto
        case "signedNonce":       self = .signedNonce
        case "totp":              self = .totp
        case "password":          self = .password
        case "webauthn":          self = .webauthn
        case "security_question": self = .security_question
        default:                  self = .unknown
        }
    }
}

extension IDXClient.Message.MessageClass {
    internal init(string value: String) {
        switch value {
        case "ERROR": self = .error
        case "INFO":  self = .info
        default:      self = .unknown
        }
    }
}
