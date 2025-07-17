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

// swiftlint:disable cyclomatic_complexity
extension Authenticator.Kind: RawRepresentable {
    public init(rawValue value: String) {
        switch value {
        case "app":               self = .app
        case "email":             self = .email
        case "phone":             self = .phone
        case "password":          self = .password
        case "security_question": self = .securityQuestion
        case "device":            self = .device
        case "security_key":      self = .securityKey
        case "federated":         self = .federated
        default:                  self = .other(type: value)
        }
    }

    public var rawValue: String {
        switch self {
        case .app:              return "app"
        case .email:            return "email"
        case .phone:            return "phone"
        case .password:         return "password"
        case .securityQuestion: return "security_question"
        case .device:           return "device"
        case .securityKey:      return "security_key"
        case .federated:        return "federated"
        case .other(let type):  return type
        }
    }
}

extension Authenticator.Method: RawRepresentable {
    public init(rawValue value: String) {
        switch value {
        case "sms":               self = .sms
        case "voice":             self = .voice
        case "email":             self = .email
        case "push":              self = .push
        case "signedNonce":       self = .signedNonce
        case "totp":              self = .totp
        case "otp":               self = .otp
        case "password":          self = .password
        case "webauthn":          self = .webAuthN
        case "security_question": self = .securityQuestion
        case "idp":               self = .idp
        case "duo":               self = .duo
        case "federated":         self = .federated // TODO: This is shown as deprecated; should we care about it?
        default:                  self = .other(type: value)
        }
    }

    public var rawValue: String {
        switch self {
        case .sms:              return "sms"
        case .voice:            return "voice"
        case .email:            return "email"
        case .push:             return "push"
        case .signedNonce:      return "signedNonce"
        case .totp:             return "totp"
        case .otp:              return "otp"
        case .password:         return "password"
        case .webAuthN:         return "webauthn"
        case .securityQuestion: return "security_question"
        case .idp:              return "idp"
        case .duo:              return "duo"
        case .federated:        return "federated"
        case .other(let type):  return type
        }
    }
}

extension Remediation.RemediationType {
    public static func == (lhs: Remediation.RemediationType, rhs: Remediation.RemediationType) -> Bool {
        switch (lhs, rhs) {
        case (.identify, .identify),
            (.identifyRecovery, .identifyRecovery),
            (.selectIdentify, .selectIdentify),
            (.selectEnrollProfile, .selectEnrollProfile),
            (.cancel, .cancel),
            (.sendChallenge, .sendChallenge),
            (.resendChallenge, .resendChallenge),
            (.send, .send),
            (.resend, .resend),
            (.selectAuthenticatorAuthenticate, .selectAuthenticatorAuthenticate),
            (.selectAuthenticatorUnlockAccount, .selectAuthenticatorUnlockAccount),
            (.selectAuthenticatorEnroll, .selectAuthenticatorEnroll),
            (.selectEnrollmentChannel, .selectEnrollmentChannel),
            (.authenticatorVerificationData, .authenticatorVerificationData),
            (.authenticatorEnrollmentData, .authenticatorEnrollmentData),
            (.enrollmentChannelData, .enrollmentChannelData),
            (.challengeAuthenticator, .challengeAuthenticator),
            (.poll, .poll),
            (.enrollPoll, .enrollPoll),
            (.recover, .recover),
            (.enrollAuthenticator, .enrollAuthenticator),
            (.reenrollAuthenticator, .reenrollAuthenticator),
            (.reenrollAuthenticatorWarning, .reenrollAuthenticatorWarning),
            (.resetAuthenticator, .resetAuthenticator),
            (.enrollProfile, .enrollProfile),
            (.unlockAccount, .unlockAccount),
            (.deviceChallengePoll, .deviceChallengePoll),
            (.cancelPolling, .cancelPolling),
            (.deviceAppleSsoExtension, .deviceAppleSsoExtension),
            (.launchAuthenticator, .launchAuthenticator),
            (.redirectIdp, .redirectIdp),
            (.cancelTransaction, .cancelTransaction),
            (.skip, .skip),
            (.challengePoll, .challengePoll),
            (.consent, .consent),
            (.adminConsent, .adminConsent),
            (.emailChallengeConsent, .emailChallengeConsent),
            (.requestActivationEmail, .requestActivationEmail),
            (.userCode, .userCode),
            (.challengeWebAuthnAutofillUIAuthenticator, .challengeWebAuthnAutofillUIAuthenticator):
            return true
        case (.unknown(let lhs), .unknown(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }

    internal init(string value: String) {
        switch value {
        case "identify":                            self = .identify
        case "identify-recovery":                   self = .identifyRecovery
        case "select-identify":                     self = .selectIdentify
        case "select-enroll-profile":               self = .selectEnrollProfile
        case "cancel":                              self = .cancel
        case "send-challenge":                      self = .sendChallenge
        case "resend-challenge":                    self = .resendChallenge
        case "send":                                self = .send
        case "resend":                              self = .resend
        case "select-authenticator-authenticate":   self = .selectAuthenticatorAuthenticate
        case "select-authenticator-unlock-account": self = .selectAuthenticatorUnlockAccount
        case "select-authenticator-enroll":         self = .selectAuthenticatorEnroll
        case "select-enrollment-channel":           self = .selectEnrollmentChannel
        case "authenticator-verification-data":     self = .authenticatorVerificationData
        case "authenticator-enrollment-data":       self = .authenticatorEnrollmentData
        case "enrollment-channel-data":             self = .enrollmentChannelData
        case "challenge-authenticator":             self = .challengeAuthenticator
        case "poll":                                self = .poll
        case "enroll-poll":                         self = .enrollPoll
        case "recover":                             self = .recover
        case "enroll-authenticator":                self = .enrollAuthenticator
        case "reenroll-authenticator":              self = .reenrollAuthenticator
        case "reenroll-authenticator-warning":      self = .reenrollAuthenticatorWarning
        case "reset-authenticator":                 self = .resetAuthenticator
        case "enroll-profile":                      self = .enrollProfile
        case "unlock-account":                      self = .unlockAccount
        case "device-challenge-poll":               self = .deviceChallengePoll
        case "cancel-polling":                      self = .cancelPolling
        case "device-apple-sso-extension":          self = .deviceAppleSsoExtension
        case "launch-authenticator":                self = .launchAuthenticator
        case "redirect-idp":                        self = .redirectIdp
        case "cancel-transaction":                  self = .cancelTransaction
        case "skip":                                self = .skip
        case "challenge-poll":                      self = .challengePoll
        case "consent":                             self = .consent
        case "admin-consent":                       self = .adminConsent
        case "email-challenge-consent":             self = .emailChallengeConsent
        case "request-activation-email":            self = .requestActivationEmail
        case "user-code":                           self = .userCode
        case "challenge-webauthn-autofillui-authenticator":
            self = .challengeWebAuthnAutofillUIAuthenticator
        default:                                    self = .unknown(value)
        }
    }
}

extension Response.Intent {
    public init(string: String?) {
        switch string {
        case "ENROLL_NEW_USER":
            self = .enrollNewUser
        case "LOGIN":
            self = .login
        case "CREDENTIAL_ENROLLMENT":
            self = .credentialEnrollment
        case "CREDENTIAL_UNENROLLMENT":
            self = .credentialUnenrollment
        case "CREDENTIAL_RECOVERY":
            self = .credentialRecovery
        case "CREDENTIAL_MODIFY":
            self = .credentialModify
        default:
            self = .unknown
        }
    }
}

extension SocialIDPCapability.Service: RawRepresentable {
    public typealias RawValue = String

    public init(string: String) {
        switch string {
        case "SAML2":         self = .saml
        case "GOOGLE":        self = .google
        case "FACEBOOK":      self = .facebook
        case "LINKEDIN":      self = .linkedin
        case "MICROSOFT":     self = .microsoft
        case "OIDC":          self = .oidc
        case "OKTA":          self = .okta
        case "IWA":           self = .iwa
        case "AgentlessDSSO": self = .agentlessIwa
        case "X509":          self = .x509
        case "APPLE":         self = .apple
        case "OIN_SOCIAL":    self = .oinSocial
        default:              self = .other(string)
        }
    }

    public init?(rawValue: String) {
        self.init(string: rawValue)
    }

    public var rawValue: String {
        switch self {
        case .saml:               return "SAML2"
        case .google:             return "GOOGLE"
        case .facebook:           return "FACEBOOK"
        case .linkedin:           return "LINKEDIN"
        case .microsoft:          return "MICROSOFT"
        case .oidc:               return "OIDC"
        case .okta:               return "OKTA"
        case .iwa:                return "IWA"
        case .agentlessIwa:       return "AgentlessDSSO"
        case .x509:               return "X509"
        case .apple:              return "APPLE"
        case .oinSocial:          return "OIN_SOCIAL"
        case .other(let service): return service
        }
    }
}

extension Authenticator.Method {
    public var stringValue: String? {
        switch self {
        case .sms:
            return "sms"
        case .voice:
            return "voice"
        case .email:
            return "email"
        case .push:
            return "push"
        case .signedNonce:
            return "signedNonce"
        case .totp:
            return "totp"
        case .otp:
            return "otp"
        case .password:
            return "password"
        case .webAuthN:
            return "webAuthN"
        case .securityQuestion:
            return "securityQuestion"
        case .idp:
            return "idp"
        case .duo:
            return "duo"
        case .federated:
            return "federated"
        case .other(type: let type):
            return type
        }
    }
}
// swiftlint:enable cyclomatic_complexity
