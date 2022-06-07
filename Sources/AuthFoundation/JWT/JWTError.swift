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

public enum JWTError: Error, Equatable {
    case invalidBase64Encoding
    case badTokenStructure
    case invalidIssuer
    case invalidAudience
    case issuerRequiresHTTPS
    case invalidSigningAlgorithm
    case expired
    case issuedAtTimeExceedsGraceInterval
    case cannotCreateKey(code: OSStatus, description: String?)
    case invalidKey
    case unsupportedAlgorithm(_ algorithm: JWK.Algorithm)
    case cannotGenerateHash
    case signatureVerificationUnavailable
    case signatureInvalid
}

extension JWTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidBase64Encoding:
            return NSLocalizedString("invalid_base64_encoding",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .badTokenStructure:
            return NSLocalizedString("bad_token_structure",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        case .invalidIssuer:
            return NSLocalizedString("invalid_issuer",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidAudience:
            return NSLocalizedString("invalid_audience",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .issuerRequiresHTTPS:
            return NSLocalizedString("issuer_requires_https",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidSigningAlgorithm:
            return NSLocalizedString("invalid_signing_algorithm",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .expired:
            return NSLocalizedString("token_expired",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .issuedAtTimeExceedsGraceInterval:
            return NSLocalizedString("issuedAt_time_exceeds_grace_interval",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")


        case .cannotCreateKey(code: _, description: _):
            return NSLocalizedString("cannot_create_key",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidKey:
            return NSLocalizedString("invalid_key",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .signatureInvalid:
            return NSLocalizedString("signature_invalid",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .signatureVerificationUnavailable:
            return NSLocalizedString("signature_verification_unavailable",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .unsupportedAlgorithm(let algorithm):
            return String.localizedStringWithFormat(
                NSLocalizedString("unsupported_algorithm",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                algorithm.rawValue)
        
        case .cannotGenerateHash:
            return NSLocalizedString("cannot_generate_hash",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        }
    }
}
