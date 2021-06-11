//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
        case "FACEBOOK":
            self = .facebook
        case "GOOGLE":
            self = .google
        case "LINKEDIN":
            self = .linkedin
        default:
            self = .other
        }
    }
}
