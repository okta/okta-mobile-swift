//
//  IDXResponseTypeTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-01-21.
//

import XCTest
@testable import OktaIdx

class IDXResponseTypeTests: XCTestCase {
    typealias RemediationType = IDXClient.Remediation.RemediationType
    func testInitializer() throws {
        XCTAssertEqual(RemediationType(string: "identify"), .identify)
        XCTAssertEqual(RemediationType(string: "select-identify"), .selectIdentify)
        XCTAssertEqual(RemediationType(string: "select-enroll-profile"), .selectEnrollProfile)
        XCTAssertEqual(RemediationType(string: "cancel"), .cancel)
        XCTAssertEqual(RemediationType(string: "activate-factor"), .activateFactor)
        XCTAssertEqual(RemediationType(string: "send"), .sendChallenge)
        XCTAssertEqual(RemediationType(string: "resend"), .resendChallenge)
        XCTAssertEqual(RemediationType(string: "select-factor-authenticate"), .selectFactorAuthenticate)
        XCTAssertEqual(RemediationType(string: "select-factor-enroll"), .selectFactorEnroll)
        XCTAssertEqual(RemediationType(string: "challenge-factor"), .challengeFactor)
        XCTAssertEqual(RemediationType(string: "select-authenticator-authenticate"), .selectAuthenticatorAuthenticate)
        XCTAssertEqual(RemediationType(string: "select-authenticator-enroll"), .selectAuthenticatorEnroll)
        XCTAssertEqual(RemediationType(string: "select-enrollment-channel"), .selectEnrollmentChannel)
        XCTAssertEqual(RemediationType(string: "authenticator-verification-data"), .authenticatorVerificationData)
        XCTAssertEqual(RemediationType(string: "authenticator-enrollment-data"), .authenticatorEnrollmentData)
        XCTAssertEqual(RemediationType(string: "enrollment-channel-data"), .enrollmentChannelData)
        XCTAssertEqual(RemediationType(string: "challenge-authenticator"), .challengeAuthenticator)
        XCTAssertEqual(RemediationType(string: "poll"), .poll)
        XCTAssertEqual(RemediationType(string: "enroll-poll"), .enrollPoll)
        XCTAssertEqual(RemediationType(string: "recover"), .recover)
        XCTAssertEqual(RemediationType(string: "enroll-factor"), .enrollFactor)
        XCTAssertEqual(RemediationType(string: "enroll-authenticator"), .enrollAuthenticator)
        XCTAssertEqual(RemediationType(string: "reenroll-authenticator"), .reenrollAuthenticator)
        XCTAssertEqual(RemediationType(string: "reenroll-authenticator-warning"), .reenrollAuthenticatorWarning)
        XCTAssertEqual(RemediationType(string: "reset-authenticator"), .resetAuthenticator)
        XCTAssertEqual(RemediationType(string: "enroll-profile"), .enrollProfile)
        XCTAssertEqual(RemediationType(string: "profile-attributes"), .profileAttributes)
        XCTAssertEqual(RemediationType(string: "select-idp"), .selectIdp)
        XCTAssertEqual(RemediationType(string: "select-platform"), .selectPlatform)
        XCTAssertEqual(RemediationType(string: "factor-poll-verification"), .factorPollVerification)
        XCTAssertEqual(RemediationType(string: "qr-refresh"), .qrRefresh)
        XCTAssertEqual(RemediationType(string: "device-challenge-poll"), .deviceChallengePoll)
        XCTAssertEqual(RemediationType(string: "cancel-polling"), .cancelPolling)
        XCTAssertEqual(RemediationType(string: "device-apple-sso-extension"), .deviceAppleSsoExtension)
        XCTAssertEqual(RemediationType(string: "launch-authenticator"), .launchAuthenticator)
        XCTAssertEqual(RemediationType(string: "redirect"), .redirect)
        XCTAssertEqual(RemediationType(string: "redirect-idp"), .redirectIdp)
        XCTAssertEqual(RemediationType(string: "cancel-transaction"), .cancelTransaction)
        XCTAssertEqual(RemediationType(string: "skip"), .skip)
        XCTAssertEqual(RemediationType(string: "challenge-poll"), .challengePoll)
        XCTAssertEqual(RemediationType(string: "something invalid"), .unknown)
    }
}
