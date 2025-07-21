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

// swiftlint:disable cyclomatic_complexity
extension WebAuthnCapabilityError: Equatable {
    public static func == (lhs: WebAuthnCapabilityError,
                           rhs: WebAuthnCapabilityError) -> Bool
    {
        switch (lhs, rhs) {
        case (.missingChallengeJson, .missingChallengeJson): return true
        case (.missingRelyingPartyIdentifier, .missingRelyingPartyIdentifier): return true
        case (.invalidRemediationForm, .invalidRemediationForm): return true
        case (.unsupportedCredentialType, .unsupportedCredentialType): return true
        default:
            return false
        }
    }
}

extension WebAuthnCapabilityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingChallengeJson:
            return NSLocalizedString("webauthn_missing_challenge_json",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "Missing WebAuthn challenge JSON data")

        case .missingRelyingPartyIdentifier:
            return NSLocalizedString("webauthn_missing_relying_party_identifier",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "Missing relying party identifier/domain")

        case .invalidRemediationForm:
            return NSLocalizedString("webauthn_invalid_remediation_form",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "Remediation form for WebAuthn response is invalid")

        case .unsupportedCredentialType:
            return NSLocalizedString("webauthn_unsupported_credential_type",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "The WebAuthn credential type is not supported")
        }
    }
}
// swiftlint:enable cyclomatic_complexity
