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

extension Remediation {
    /// Enumeration describing the possible remedation types. This is expanded from the possible option values that may be present in the `name` property.
    public enum RemediationType {
        case unknown
        
        /// Used to identify a user's username.
        case identify
        
        /// Used to identify a user's username as part of the account recovery process.
        case identifyRecovery
        
        /// Used to allow a user to select that they would like to sign in with their username.
        case selectIdentify
        
        /// Used to allow the user to enroll in a new profile, also known as "self service registration".
        case selectEnrollProfile
        
        /// Allows the user to cancel and restart the authentication flow from the beginning.
        case cancel
        
        case sendChallenge
        case resendChallenge
        
        /// Used to prompt a user for a list of authenticators, from which they can select which they would like to verify their account.
        case selectAuthenticatorAuthenticate

        /// Used to select an authenticator type to use to unlock a user's account.
        case selectAuthenticatorUnlockAccount

        /// Used to prompt a user for a list of authenticators, giving them a choice as to which authenticator they would like to enroll in.
        case selectAuthenticatorEnroll
        case selectEnrollmentChannel
        case authenticatorVerificationData
        case authenticatorEnrollmentData
        case enrollmentChannelData
        
        /// Used to supply a challenge to an authenticator, such as prompting a user for their password, or supplying a factor's verification code such as a SMS or Email one-time-password.
        case challengeAuthenticator
        case enrollPoll
        case enrollAuthenticator
        case reenrollAuthenticator
        case reenrollAuthenticatorWarning
        case resetAuthenticator
        
        /// Used to enroll the user in a new profile, also
        case enrollProfile
        case unlockAccount
        case deviceChallengePoll
        case deviceAppleSsoExtension
        
        /// Used to launch a separate authenticator application, such as Okta Verify.
        case launchAuthenticator
        
        /// Used to redirect the user to another IDP, such as Facebook or Twitter authentication.
        case redirectIdp
        case cancelTransaction
        
        /// Enables a user to skip the current step, for example, skipping enrolment in optional authenticators.
        case skip
        case challengePoll
        case cancelPolling
        case consent
        case adminConsent
        case emailChallengeConsent
        case requestActivationEmail
        case userCode

        /// Underlying authenticator action used by the ``Capability.Pollable`` capability.
        case poll

        /// Underlying authenticator action used by the ``Capability.Recoverable`` capability.
        case recover

        /// Underlying authenticator action used by the ``Capability.Sendable`` capability.
        case send
        
        /// Underlying authenticator action used by the ``Capability.Resendable`` capability.
        case resend
    }
}
