//
//  IDXClient+Extension.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient {
    internal class APIVersion1 {
        static let version = Version.v1_0_0
        var stateHandle: String? = nil
        var interactionHandle: String? = nil
        var cancelRemediationOption: IDXClient.Remediation.Option? = nil
        
        let configuration: IDXClient.Configuration
        let session: URLSessionProtocol
        weak var delegate: IDXClientAPIDelegate?

        init(with configuration: Configuration, session: URLSessionProtocol? = nil) {
            self.configuration = configuration
            self.session = session ?? URLSession(configuration: URLSessionConfiguration.ephemeral)
        }
    }
    
    public func start(completion: @escaping (Response?, Error?) -> Void) {
        self.api.start { (response, error) in
            self.queue.async {
                completion(response, error)
            }
        }
    }
    
    public var canCancel: Bool {
        return self.api.canCancel
    }
    
    public func cancel(completion: @escaping (Response?, Error?) -> Void)
    {
        self.api.cancel { (response, error) in
            self.queue.async {
                completion(response, error)
            }
        }
    }
    
    public func proceed(remediation option: Remediation.Option,
                        data: [String : Any]? = nil,
                        completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.proceed(remediation: option, data: data) { (response, error) in
            self.queue.async {
                completion(response, error)
            }
        }
    }
    
    public func exchangeCode(using successResponse: Remediation.Option, completion: @escaping (Token?, Error?) -> Void) {
        self.api.exchangeCode(using: successResponse) { (token, error) in
            self.queue.async {
                completion(token, error)
            }
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

extension IDXClient: IDXClientAPIDelegate {
    func clientAPIStateHandleChanged(stateHandle: String?) {
        print("State handle changed to \(stateHandle)")
    }
}

