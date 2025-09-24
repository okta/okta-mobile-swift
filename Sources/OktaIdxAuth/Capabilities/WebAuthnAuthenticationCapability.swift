//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import CommonSupport
import AuthFoundation

#if !COCOAPODS
import CommonSupport
#endif

/// Capability for authenticating a user with an existing WebAuthn credential.
///
/// This represents the authentication portion of WebAuthn sign-in, and is used to complete a WebAuthn or Passkey authentication request. The properties exposed here may be used individually, or the ``createCredentialAssertionRequest()`` convenience function may be used to produce a request suitable for presentation to the user.
///
/// Once the platform authenticator has completed creating an assertion response, the resulting data can be supplied to the ``challenge(authenticatorData:clientData:signatureData:)`` function to validate the results with the server. Alternatively the ``challenge(credential:)`` convenience function may be used with the passkey authenticator assertion response.
public final class WebAuthnAuthenticationCapability: Capability, Sendable, Equatable, Hashable {
    nonisolated let rawChallengeJSON: JSON
    
    /// The relying party identifier indicated on the credential assertion request issued from the server.
    public nonisolated var relyingPartyIdentifier: String {
        get { lock.withLock { _relyingPartyIdentifier } }
        set { lock.withLock { _relyingPartyIdentifier = newValue } }
    }

    /// The authentication challenge data in the credential assertion request issued from the server.
    public nonisolated let challenge: Data

    /// The user verification preference represented as its underlying string value, if any, indicated in the credential assertion request issued from the server.
    public nonisolated let userVerificationPreferenceString: String?

    /// Completes a WebAuthn assertion challenge request by submitting the passkey authenticator's results to the server.
    /// - Parameters:
    ///   - authenticatorData: Authenticator data.
    ///   - clientData: Client data.
    ///   - signatureData: Signature data.
    ///   - userHandle: Optional user handle, when used with an autofill UI challenge remediation.
    /// - Returns: The ``Response`` for the next step of the authentication flow.
    public func challenge(authenticatorData: Data,
                          clientData: Data,
                          signatureData: Data,
                          userHandle: Data? = nil) async throws -> Response
    {
        guard let remediation,
              remediation.type == .challengeAuthenticator ||
                remediation.type == .challengeWebAuthnAutofillUIAuthenticator,
              let authenticatorDataField = remediation.form[allFields: "credentials.authenticatorData"],
              let clientDataField = remediation.form[allFields: "credentials.clientData"],
              let signatureDataField = remediation.form[allFields: "credentials.signatureData"]
        else {
            throw WebAuthnCapabilityError.invalidRemediationForm
        }

        authenticatorDataField.value = authenticatorData.base64EncodedString()
        clientDataField.value = clientData.base64EncodedString()
        signatureDataField.value = signatureData.base64EncodedString()

        if let userHandle,
           remediation.type == .challengeWebAuthnAutofillUIAuthenticator
        {
            guard let userHandleField = remediation.form[allFields: "credentials.userHandle"]
            else {
                throw WebAuthnCapabilityError.invalidRemediationForm
            }

            if let value = String(data: userHandle, encoding: .utf8) {
                userHandleField.value = value
            } else {
                userHandleField.value = userHandle.base64EncodedString()
            }
        }

        return try await remediation.proceed()
    }

    @_documentation(visibility: internal)
    public static func == (lhs: WebAuthnAuthenticationCapability, rhs: WebAuthnAuthenticationCapability) -> Bool {
        lhs.rawChallengeJSON == rhs.rawChallengeJSON &&
        lhs.relyingPartyIdentifier == rhs.relyingPartyIdentifier
    }

    @_documentation(visibility: internal)
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawChallengeJSON)
        hasher.combine(relyingPartyIdentifier)
    }

    var remediation: Remediation? {
        get { lock.withLock { _remediation } }
        set { lock.withLock { _remediation = newValue } }
    }

    private let lock = Lock()
    nonisolated(unsafe) private weak var _remediation: Remediation?
    nonisolated(unsafe) var _relyingPartyIdentifier: String
    internal init(issuerURL: URL, rawChallengeJSON json: JSON) throws {
        guard case let .string(challengeString) = json["challenge"],
              let challenge = Data(base64Encoded: challengeString.base64URLDecoded)
        else {
            throw WebAuthnCapabilityError.missingChallengeJson
        }

        self.rawChallengeJSON = json
        self.challenge = challenge
        self._relyingPartyIdentifier = try String.relyingPartyIssuer(from: json,
                                                                     issuerURL: issuerURL)

        if case let .string(userVerification) = json["userVerification"] {
            userVerificationPreferenceString = userVerification
        } else {
            userVerificationPreferenceString = nil
        }
    }
}

extension WebAuthnAuthenticationCapability: ReferencesParent {
    func assign<ParentType>(parent: ParentType?) {
        guard let remediation = parent as? Remediation else { return }

        self.remediation = remediation
    }
}

#if canImport(AuthenticationServices) && !os(watchOS)
import AuthenticationServices

@available(iOS 15.0, macCatalyst 15.0, macOS 12.0, tvOS 16.0, visionOS 1.0, *)
extension WebAuthnAuthenticationCapability {
    /// Creates Passkey / WebAuthn credential assertion request suitable to be presented to the user.
    ///
    /// The request object returned from this may be customized before presentation, or may be used as-is. For example:
    ///
    /// ```swift
    /// if let remediation = response.remediations[.challengeAuthenticator],
    ///    let capability = remediation.webAuthnAuthentication
    /// {
    ///     let authController = ASAuthorizationController(authorizationRequests: [
    ///         capability.createCredentialAssertionRequest()
    ///     ])
    ///     authController.delegate = self
    ///     authController.presentationContextProvider = self
    ///     authController.performRequests()
    /// }
    /// ```
    /// - Returns: Configured credential assertion request.
    public nonisolated func createPlatformCredentialAssertionRequest() -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = platformProvider.createCredentialAssertionRequest(challenge: challenge)
        request.userVerificationPreference = userVerificationPreference

        return request
    }

    #if !os(tvOS) && !os(visionOS)
    /// Creates Security Key / WebAuthn credential assertion request suitable to be presented to the user.
    ///
    /// The request object returned from this may be customized before presentation, or may be used as-is. For example:
    ///
    /// ```swift
    /// if let remediation = response.remediations[.challengeAuthenticator],
    ///    let capability = remediation.webAuthnAuthentication
    /// {
    ///     let authController = ASAuthorizationController(authorizationRequests: [
    ///         capability.createCredentialAssertionRequest()
    ///     ])
    ///     authController.delegate = self
    ///     authController.presentationContextProvider = self
    ///     authController.performRequests()
    /// }
    /// ```
    /// - Returns: Configured credential assertion request.
    public nonisolated func createSecurityKeyCredentialAssertionRequest() -> ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest {
        let platformProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = platformProvider.createCredentialAssertionRequest(challenge: challenge)
        request.userVerificationPreference = userVerificationPreference

        return request
    }
    #endif
    
    /// The user verification preference, if any, indicated in the credential assertion request issued from the server.
    public nonisolated var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference {
        guard let userVerificationPreferenceString else {
            return .preferred
        }

        return ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerificationPreferenceString)
    }

    /// Completes a WebAuthn assertion challenge request by submitting the passkey authenticator's results to the server.
    /// - Parameter credential: The Authorization Services credential assertion response from the platform authenticator.
    /// - Returns: The ``Response`` for the next step of the authentication flow.
    public func challenge(credential: any ASAuthorizationPublicKeyCredentialAssertion) async throws -> Response {
        guard let authenticatorData = credential.rawAuthenticatorData,
              let signatureData = credential.signature
        else {
            throw WebAuthnCapabilityError.unsupportedCredentialType
        }
        return try await challenge(authenticatorData: authenticatorData,
                                   clientData: credential.rawClientDataJSON,
                                   signatureData: signatureData,
                                   userHandle: credential.userID)
    }
}
#endif
