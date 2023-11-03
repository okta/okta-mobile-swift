//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Describes errors that may occur with parsing or validating JWT tokens.
public enum JWTError: Error, Equatable {
    case invalidBase64Encoding
    case badTokenStructure
    case invalidIssuer
    case invalidAudience
    case invalidSubject
    case invalidAuthenticationTime
    case issuerRequiresHTTPS
    case invalidSigningAlgorithm
    case expired
    case issuedAtTimeExceedsGraceInterval
    case nonceMismatch
    case cannotCreateKey(code: OSStatus, description: String?)
    case invalidKey
    case unsupportedAlgorithm(_ algorithm: JWK.Algorithm)
    case cannotGenerateHash
    case signatureVerificationUnavailable
    case signatureInvalid
    case exceedsMaxAge
}

extension JWTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidBase64Encoding:
            return NSLocalizedString("jwt_invalid_base64_encoding",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .badTokenStructure:
            return NSLocalizedString("jwt_bad_token_structure",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        case .invalidIssuer:
            return NSLocalizedString("jwt_invalid_issuer",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidAudience:
            return NSLocalizedString("jwt_invalid_audience",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidSubject:
            return NSLocalizedString("jwt_invalid_subject",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidAuthenticationTime:
            return NSLocalizedString("jwt_invalid_authentication_time",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .issuerRequiresHTTPS:
            return NSLocalizedString("jwt_issuer_requires_https",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidSigningAlgorithm:
            return NSLocalizedString("jwt_invalid_signing_algorithm",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .expired:
            return NSLocalizedString("jwt_token_expired",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .issuedAtTimeExceedsGraceInterval:
            return NSLocalizedString("jwt_issuedAt_time_exceeds_grace_interval",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .nonceMismatch:
            return NSLocalizedString("jwt_nonce_mismatch",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .cannotCreateKey:
            return NSLocalizedString("jwt_cannot_create_key",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidKey:
            return NSLocalizedString("jwt_invalid_key",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .signatureInvalid:
            return NSLocalizedString("jwt_signature_invalid",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .signatureVerificationUnavailable:
            return NSLocalizedString("jwt_signature_verification_unavailable",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .unsupportedAlgorithm(let algorithm):
            return String.localizedStringWithFormat(
                NSLocalizedString("jwt_unsupported_algorithm",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                algorithm.rawValue)
            
        case .cannotGenerateHash:
            return NSLocalizedString("jwt_cannot_generate_hash",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .exceedsMaxAge:
            return NSLocalizedString("jwt_exceeds_max_age",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        }
    }
}
