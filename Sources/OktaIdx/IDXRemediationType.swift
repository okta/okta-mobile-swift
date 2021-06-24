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

extension IDXClient.Remediation {
    /// Enumeration describing the possible remedation types. This is expanded from the possible option values that may be present in the `name` property.
    @objc(IDXRemediationType)
    public enum RemediationType: Int {
        case unknown
        case identify
        case identifyRecovery
        case selectIdentify
        case selectEnrollProfile
        case cancel
        case activateFactor
        case sendChallenge
        case resendChallenge
        case selectFactorAuthenticate
        case selectFactorEnroll
        case challengeFactor
        case selectAuthenticatorAuthenticate
        case selectAuthenticatorEnroll
        case selectEnrollmentChannel
        case authenticatorVerificationData
        case authenticatorEnrollmentData
        case enrollmentChannelData
        case challengeAuthenticator
        case poll
        case enrollPoll
        case recover
        case enrollFactor
        case enrollAuthenticator
        case reenrollAuthenticator
        case reenrollAuthenticatorWarning
        case resetAuthenticator
        case enrollProfile
        case profileAttributes
        case selectIdp
        case selectPlatform
        case factorPollVerification
        case qrRefresh
        case deviceChallengePoll
        case cancelPolling
        case deviceAppleSsoExtension
        case launchAuthenticator
        case redirect
        case redirectIdp
        case cancelTransaction
        case skip
        case challengePoll
    }
}
