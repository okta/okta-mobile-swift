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

public enum WebAuthnCapabilityError: Error {
    case missingUserData
    case missingRelyingPartyIdentifier
    case invalidRemediationForm
}

/// Capability for registering / enrolling a user with a new WebAuthn credential.
public final class WebAuthnRegistrationCapability: Capability, Sendable, Equatable, Hashable {
    /// JSON data representing the WebAuthn authenticator activation capability.
    ///
    /// This usually contains redacted information relevant to display to the user.
    public nonisolated let rawActivationJSON: JSON

    public nonisolated let challenge: Data

    public nonisolated let displayName: String

    public nonisolated let name: String

    public nonisolated let userId: Data

    public nonisolated let relyingPartyIdentifier: String

    public func register(attestation: Data,
                         clientJSON: Data) async throws -> Response
    {
        guard let remediation,
              let attestationField = remediation.form[allFields: "credentials.attestation"],
              let clientDataField = remediation.form[allFields: "credentials.clientData"]
        else {
            throw WebAuthnCapabilityError.invalidRemediationForm
        }

        attestationField.value = attestation.base64EncodedString()
        clientDataField.value = clientJSON.base64EncodedString()
        return try await remediation.proceed()
    }

    public static func == (lhs: WebAuthnRegistrationCapability, rhs: WebAuthnRegistrationCapability) -> Bool {
        lhs.rawActivationJSON == rhs.rawActivationJSON
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawActivationJSON)
    }

    var remediation: Remediation? {
        get { lock.withLock { _remediation } }
        set { lock.withLock { _remediation = newValue } }
    }

    private let lock = Lock()
    nonisolated(unsafe) private weak var _remediation: Remediation?
    internal init(issuerURL: URL, rawActivationJSON json: JSON) throws {
        guard case let .string(challengeString) = json["challenge"],
              let challenge = Data(base64Encoded: challengeString.base64URLDecoded),
              case let .object(userObject) = json["user"],
              case let .string(displayName) = userObject["displayName"],
              case let .string(name) = userObject["name"],
              case let .string(userID) = userObject["id"]
        else {
            throw WebAuthnCapabilityError.missingUserData
        }


        self.rawActivationJSON = json
        self.challenge = challenge
        self.userId = Data(userID.utf8)
        self.displayName = displayName
        self.name = name
        self.relyingPartyIdentifier = try String.relyingPartyIssuer(from: json,
                                                                    issuerURL: issuerURL)
    }
}

extension WebAuthnRegistrationCapability: ReferencesParent {
    func assign<ParentType>(parent: ParentType?) {
        guard let remediation = parent as? Remediation else { return }

        self.remediation = remediation
    }
}
