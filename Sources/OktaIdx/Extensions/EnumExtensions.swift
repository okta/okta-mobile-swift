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

extension IDXClient.Authenticator.Kind {
    internal init(string value: String) {
        switch value {
        case "app":               self = .app
        case "email":             self = .email
        case "phone":             self = .phone
        case "password":          self = .password
        case "security_question": self = .securityQuestion
        case "device":            self = .device
        case "security_key":      self = .securityKey
        case "federated":         self = .federated
        default:                  self = .unknown
        }
    }
}

extension IDXClient.Authenticator.Method {
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
        case "webauthn":          self = .webAuthN
        case "security_question": self = .securityQuestion
        default:                  self = .unknown
        }
    }
}

extension IDXClient.Remediation.RemediationType {
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
        default:                                    self = .unknown
        }
    }
}

extension IDXClient.Response.Intent {
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

extension IDXClient.Remediation.SocialAuth.Service {
    public init(string: String) {
        switch string {
        case "SAML2":        self = .saml         
        case "GOOGLE":       self = .google       
        case "FACEBOOK":     self = .facebook     
        case "LINKEDIN":     self = .linkedin     
        case "MICROSOFT":    self = .microsoft    
        case "OIDC":         self = .oidc         
        case "OKTA":         self = .okta         
        case "IWA":          self = .iwa          
        case "AgentlessDSSO":self = .agentless_iwa
        case "X509":         self = .x509         
        case "APPLE":        self = .apple        
        case "OIN_SOCIAL":   self = .oin_social   
        default:             self = .other
        }
    }
}

extension IDXClient.Authenticator.Method {
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
        case .crypto:
            return "crypto"
        case .signedNonce:
            return "signedNonce"
        case .totp:
            return "totp"
        case .password:
            return "password"
        case .webAuthN:
            return "webAuthN"
        case .securityQuestion:
            return "securityQuestion"
        case .unknown:
            return nil
        }
    }
}
