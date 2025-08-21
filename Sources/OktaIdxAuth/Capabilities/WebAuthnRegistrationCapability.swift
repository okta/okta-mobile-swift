//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import AuthFoundation

#if !COCOAPODS
import CommonSupport
#endif

public enum WebAuthnCapabilityError: Error {
    case missingChallengeJson
    case missingRelyingPartyIdentifier
    case invalidRemediationForm
    case unsupportedCredentialType
}

/// Capability for registering / enrolling a user with a new WebAuthn credential.
///
/// This represents the enrollment portion of WebAuthn sign-in, and is used to complete a WebAuthn or Passkey credential creation request. The properties exposed here may be used individually, or the ``createCredentialRegistrationRequest()`` convenience function may be used to produce a request suitable for presentation to the user.
///
/// Once the platform authenticator has completed creating an attestation response, the resulting data can be supplied to the ``register(attestation:clientJSON:)`` function to validate the results with the server. Alternatively the ``register(credential:)``
public final class WebAuthnRegistrationCapability: Capability, Sendable, Equatable, Hashable {
    nonisolated let rawActivationJSON: JSON.Value
    
    /// The challenge data indicated on the credential assertion request issued from the server.
    public nonisolated let challenge: Data
    
    /// The display name indicated on the credential assertion request issued from the server.
    public nonisolated let displayName: String
    
    /// The user name indicated on the credential assertion request issued from the server.
    public nonisolated let name: String
    
    /// The credential / user ID indicated on the credential assertion request issued from the server.
    public nonisolated let userId: Data
    
    /// The relying party identifier indicated on the credential assertion request issued from the server.
    public nonisolated var relyingPartyIdentifier: String {
        get { lock.withLock { _relyingPartyIdentifier } }
        set { lock.withLock { _relyingPartyIdentifier = newValue } }
    }

    /// The user verification preference indicated on the credential assertion request issued from the server.
    public nonisolated let userVerificationPreferenceString: String?

    /// The attestation preference indicated on the credential assertion request issued from the server.
    public nonisolated let attestationPreferenceString: String?
    
    /// Completes the WebAuthn credential registration request by submitting the passkey authenticator's results to the server.
    /// - Parameters:
    ///   - attestation: Attestation data
    ///   - clientJSON: Client JSON data
    /// - Returns: The ``Response`` for the next step of the authentication flow.
    public func register(attestation: Data,
                         clientJSON: Data) async throws -> Response
    {
        guard let remediation,
              remediation.type == .enrollAuthenticator,
              let attestationField = remediation.form[allFields: "credentials.attestation"],
              let clientDataField = remediation.form[allFields: "credentials.clientData"]
        else {
            throw WebAuthnCapabilityError.invalidRemediationForm
        }

        attestationField.value = attestation.base64EncodedString()
        clientDataField.value = clientJSON.base64EncodedString()
        return try await remediation.proceed()
    }

    @_documentation(visibility: internal)
    public static func == (lhs: WebAuthnRegistrationCapability, rhs: WebAuthnRegistrationCapability) -> Bool {
        lhs.rawActivationJSON == rhs.rawActivationJSON
    }

    @_documentation(visibility: internal)
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawActivationJSON)
    }

    var remediation: Remediation? {
        get { lock.withLock { _remediation } }
        set { lock.withLock { _remediation = newValue } }
    }

    private let lock = Lock()
    nonisolated(unsafe) private weak var _remediation: Remediation?
    nonisolated(unsafe) var _relyingPartyIdentifier: String
    internal init(issuerURL: URL, rawActivationJSON json: JSON.Value) throws {
        guard let challengeString = json["challenge"]?.string,
              let challenge = Data(base64Encoded: challengeString.base64URLDecoded),
              let displayName = json["user"]?["displayName"]?.string,
              let name = json["user"]?["name"]?.string,
              let userID = json["user"]?["id"]?.string
        else {
            throw WebAuthnCapabilityError.missingChallengeJson
        }

        self.rawActivationJSON = json
        self.challenge = challenge
        self.userId = Data(userID.utf8)
        self.displayName = displayName
        self.name = name
        self._relyingPartyIdentifier = try String.relyingPartyIssuer(from: json,
                                                                     issuerURL: issuerURL)

        if let userVerification = json["authenticatorSelection"]?["userVerification"]?.string
        {
            userVerificationPreferenceString = userVerification
        } else {
            userVerificationPreferenceString = nil
        }

        if let attestation = json["attestation"]?.string {
            attestationPreferenceString = attestation
        } else {
            attestationPreferenceString = nil
        }
    }
}

extension WebAuthnRegistrationCapability: ReferencesParent {
    func assign<ParentType>(parent: ParentType?) {
        guard let remediation = parent as? Remediation else { return }

        self.remediation = remediation
    }
}

#if canImport(AuthenticationServices) && !os(watchOS)
import AuthenticationServices

@available(iOS 15.0, macCatalyst 15.0, macOS 12.0, tvOS 16.0, visionOS 1.0, *)
extension WebAuthnRegistrationCapability {
    /// Creates a Passkey / WebAuthn credential registration request suitable to be presented to the user.
    ///
    /// The request object returned from this may be customized before presentation, or may be used as-is. For example:
    ///
    /// ```swift
    /// if let remediation = response.remediations[.enrollAuthenticator],
    ///    let capability = remediation.webAuthnRegistration
    /// {
    ///     let authController = ASAuthorizationController(authorizationRequests: [
    ///         capability.createCredentialRegistrationRequest()
    ///     ])
    ///     authController.delegate = self
    ///     authController.presentationContextProvider = self
    ///     authController.performRequests()
    /// }
    /// ```
    ///
    /// > Note: Since Passkeys do not support WebAuthn authenticator attestation, the ``attestationPreference`` value is not supplied to this request.
    /// - Returns: Configured credential registration request.
    public nonisolated func createPlatformRegistrationRequest() -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = platformProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                           name: name,
                                                                           userID: userId)
        request.displayName = displayName

        if let userVerificationPreferenceString {
            request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerificationPreferenceString)
        }

        return request
    }
    
    #if !os(tvOS) && !os(visionOS)
    /// Creates a Security Key WebAuthn credential registration request suitable to be presented to the user.
    ///
    /// The request object returned from this may be customized before presentation, or may be used as-is. For example:
    ///
    /// ```swift
    /// if let remediation = response.remediations[.enrollAuthenticator],
    ///    let capability = remediation.webAuthnRegistration
    /// {
    ///     let authController = ASAuthorizationController(authorizationRequests: [
    ///         capability.createCredentialRegistrationRequest()
    ///     ])
    ///     authController.delegate = self
    ///     authController.presentationContextProvider = self
    ///     authController.performRequests()
    /// }
    /// ```
    /// - Returns: Configured credential registration request.
    public nonisolated func createSecurityKeyRegistrationRequest() -> ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest {
        let platformProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = platformProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                           displayName: displayName,
                                                                           name: name,
                                                                           userID: userId)

        if case let .array(publicKeyCredParams) = rawActivationJSON["pubKeyCredParams"] {
            request.credentialParameters = publicKeyCredParams
                .filter { $0["type"] == "public-key" }
                .compactMap { $0["alg"]?.int }
                .map {
                    ASAuthorizationPublicKeyCredentialParameters(algorithm: ASCOSEAlgorithmIdentifier(rawValue: $0))
                }
        }

        if let attestationPreferenceString {
            request.attestationPreference = ASAuthorizationPublicKeyCredentialAttestationKind(rawValue: attestationPreferenceString)
        }

        if let userVerificationPreferenceString {
            request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerificationPreferenceString)
        }

        return request
    }
    #endif
    
    /// Completes the WebAuthn credential registration request by submitting the passkey authenticator's results to the server.
    /// - Parameter credential: The Authorization Services credential registration response from the platform authenticator.
    /// - Returns: The ``Response`` for the next step of the authentication flow.
    public func register(credential: any ASAuthorizationPublicKeyCredentialRegistration) async throws -> Response {
        guard let attestation = credential.rawAttestationObject else {
            throw WebAuthnCapabilityError.unsupportedCredentialType
        }

        return try await register(attestation: attestation,
                                  clientJSON: credential.rawClientDataJSON)
    }
}
#endif
