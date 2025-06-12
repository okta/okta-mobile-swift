/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdxAuth

class IDXResponseTypeTests: XCTestCase {
    typealias RemediationType = Remediation.RemediationType
    func testInitializer() throws {
        XCTAssertEqual(RemediationType(string: "identify"), .identify)
        XCTAssertEqual(RemediationType(string: "identify-recovery"), .identifyRecovery)
        XCTAssertEqual(RemediationType(string: "select-identify"), .selectIdentify)
        XCTAssertEqual(RemediationType(string: "select-enroll-profile"), .selectEnrollProfile)
        XCTAssertEqual(RemediationType(string: "cancel"), .cancel)
        XCTAssertEqual(RemediationType(string: "send-challenge"), .sendChallenge)
        XCTAssertEqual(RemediationType(string: "resend-challenge"), .resendChallenge)
        XCTAssertEqual(RemediationType(string: "select-authenticator-authenticate"), .selectAuthenticatorAuthenticate)
        XCTAssertEqual(RemediationType(string: "select-authenticator-unlock-account"), .selectAuthenticatorUnlockAccount)
        XCTAssertEqual(RemediationType(string: "select-authenticator-enroll"), .selectAuthenticatorEnroll)
        XCTAssertEqual(RemediationType(string: "select-enrollment-channel"), .selectEnrollmentChannel)
        XCTAssertEqual(RemediationType(string: "authenticator-verification-data"), .authenticatorVerificationData)
        XCTAssertEqual(RemediationType(string: "authenticator-enrollment-data"), .authenticatorEnrollmentData)
        XCTAssertEqual(RemediationType(string: "enrollment-channel-data"), .enrollmentChannelData)
        XCTAssertEqual(RemediationType(string: "challenge-authenticator"), .challengeAuthenticator)
        XCTAssertEqual(RemediationType(string: "enroll-poll"), .enrollPoll)
        XCTAssertEqual(RemediationType(string: "enroll-authenticator"), .enrollAuthenticator)
        XCTAssertEqual(RemediationType(string: "reenroll-authenticator"), .reenrollAuthenticator)
        XCTAssertEqual(RemediationType(string: "reenroll-authenticator-warning"), .reenrollAuthenticatorWarning)
        XCTAssertEqual(RemediationType(string: "reset-authenticator"), .resetAuthenticator)
        XCTAssertEqual(RemediationType(string: "enroll-profile"), .enrollProfile)
        XCTAssertEqual(RemediationType(string: "device-challenge-poll"), .deviceChallengePoll)
        XCTAssertEqual(RemediationType(string: "device-apple-sso-extension"), .deviceAppleSsoExtension)
        XCTAssertEqual(RemediationType(string: "launch-authenticator"), .launchAuthenticator)
        XCTAssertEqual(RemediationType(string: "redirect-idp"), .redirectIdp)
        XCTAssertEqual(RemediationType(string: "cancel-transaction"), .cancelTransaction)
        XCTAssertEqual(RemediationType(string: "skip"), .skip)
        XCTAssertEqual(RemediationType(string: "challenge-poll"), .challengePoll)
        XCTAssertEqual(RemediationType(string: "consent"), .consent)
        XCTAssertEqual(RemediationType(string: "admin-consent"), .adminConsent)
        XCTAssertEqual(RemediationType(string: "email-challenge-consent"), .emailChallengeConsent)
        XCTAssertEqual(RemediationType(string: "request-activation-email"), .requestActivationEmail)
        XCTAssertEqual(RemediationType(string: "user-code"), .userCode)

        XCTAssertEqual(RemediationType(string: "poll"), .poll)
        XCTAssertEqual(RemediationType(string: "recover"), .recover)
        XCTAssertEqual(RemediationType(string: "send"), .send)
        XCTAssertEqual(RemediationType(string: "resend"), .resend)
        XCTAssertEqual(RemediationType(string: "cancel-polling"), .cancelPolling)

        XCTAssertEqual(RemediationType(string: "something-invalid"), .unknown("something-invalid"))
    }
}
