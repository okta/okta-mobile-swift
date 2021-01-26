//
//  IDXClient+ResponseTypes.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2021-01-21.
//

import Foundation

extension IDXClient.Remediation {
    /// Enumeration describing the possible remedation types. This is expanded from the possible option values that may be present in the `name` property.
    @objc(IDXRemediationType)
    public enum RemediationType: Int {
        case unknown
        case identify
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
