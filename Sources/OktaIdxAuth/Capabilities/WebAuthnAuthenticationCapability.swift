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
import AuthFoundation

/// Capability for authenticating a user with an existing WebAuthn credential.
public final class WebAuthnAuthenticationCapability: Capability, Sendable, Equatable, Hashable {
    /// JSON data representing the WebAuthn authenticator authentication capability.
    ///
    /// This usually contains information used to challenge a platform authenticator
    public nonisolated let rawChallengeJSON: JSON

    public nonisolated let relyingPartyIdentifier: String

    public nonisolated let challenge: Data

    public func challenge(authenticatorData: Data,
                          clientData: Data,
                          signatureData: Data) async throws -> Response
    {
        guard let remediation,
              let authenticatorDataField = remediation.form[allFields: "credentials.authenticatorData"],
              let clientDataField = remediation.form[allFields: "credentials.clientData"],
              let signatureDataField = remediation.form[allFields: "credentials.signatureData"]
        else {
            throw WebAuthnCapabilityError.invalidRemediationForm
        }

        authenticatorDataField.value = authenticatorData.base64EncodedString()
        clientDataField.value = clientData.base64EncodedString()
        signatureDataField.value = signatureData.base64EncodedString()
        return try await remediation.proceed()
    }

    public static func == (lhs: WebAuthnAuthenticationCapability, rhs: WebAuthnAuthenticationCapability) -> Bool {
        lhs.rawChallengeJSON == rhs.rawChallengeJSON
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawChallengeJSON)
    }

    var remediation: Remediation? {
        get { lock.withLock { _remediation} }
        set { lock.withLock { _remediation = newValue } }
    }

    private let lock = Lock()
    nonisolated(unsafe) private weak var _remediation: Remediation?
    internal init(issuerURL: URL, rawChallengeJSON json: JSON) throws {
        guard case let .string(challengeString) = json["challenge"]
        else {
            throw WebAuthnCapabilityError.missingUserData
        }

        self.rawChallengeJSON = json
        self.challenge = Data(challengeString.base64URLDecoded.utf8)
        self.relyingPartyIdentifier = try String.relyingPartyIssuer(from: json,
                                                                    issuerURL: issuerURL)
    }
}

extension WebAuthnAuthenticationCapability: ReferencesParent {
    func assign<ParentType>(parent: ParentType?) {
        guard let remediation = parent as? Remediation else { return }

        self.remediation = remediation
    }
}
