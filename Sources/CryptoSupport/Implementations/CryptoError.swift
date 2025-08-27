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

/// Defines errors that can occur during cryptographic operations.
public enum CryptoError: Error, LocalizedError, Equatable {
    /// The provided key is not compatible with the requested algorithm.
    /// (e.g., using a symmetric key for an RSA operation).
    case incompatibleKey(String)

    /// The requested cryptographic algorithm is not supported by the current provider.
    case unsupportedSigningAlgorithm(Crypto.SigningAlgorithm)
    
    case unsupportedSignature(any Crypto.Signature)
    case unsupportedKey(any Crypto.KeyConvertible)
    
    /// The requested cryptographic algorithm is not supported by the current provider.
    case unsupportedEncryptionAlgorithm(Crypto.EncryptionAlgorithm)
    
    /// The provided key data is invalid or malformed.
    case invalidKeyData(String)
    
    /// The provided signature data is invalid or malformed.
    case malformedSignature(String)

    /// The cryptographic validation of a signature or authenticated data failed.
    case validationFailed(String? = nil)
    
    /// An unexpected error occurred in the underlying cryptographic library.
    case underlyingError(any Error)
    
    /// The raw representation of the encrypted data is missing or unsupported.
    case encryptedDataMissing
    
    case unsupported

    public var errorDescription: String? {
        switch self {
        case .incompatibleKey(let reason):
            return "Incompatible Key: \(reason)"
        case .unsupportedSigningAlgorithm(_):
            return "Unsupported Signing Algorithm"
        case .unsupportedEncryptionAlgorithm(_):
            return "Unsupported Encryption Algorithm"
        case .unsupportedSignature(_):
            return "Unsupported signature"
        case .unsupportedKey(_):
            return "Unsupported key"
        case .invalidKeyData(let reason):
            return "Invalid Key Data: \(reason)"
        case .malformedSignature(let reason):
            return "Malformed Signature: \(reason)"
        case .validationFailed(let reason):
            return "Validation Failed: \(reason ?? "No reason provided")"
        case .underlyingError(let error):
            return "An underlying cryptographic error occurred: \(error.localizedDescription)"
        case .unsupported:
            return "This cryptographic feature is unavailable or unsupported"
        case .encryptedDataMissing:
            return "No combined encrypted data found"
        }
    }
    
    public static func == (lhs: CryptoError, rhs: CryptoError) -> Bool {
        switch (lhs, rhs) {
        case (.unsupported, .unsupported): true
        case (.encryptedDataMissing, .encryptedDataMissing): true
        case (.incompatibleKey(let lhs), .incompatibleKey(let rhs)):
            lhs == rhs
        case (.unsupportedSigningAlgorithm(let lhs), .unsupportedSigningAlgorithm(let rhs)):
            lhs == rhs
        case (.unsupportedEncryptionAlgorithm(let lhs), .unsupportedEncryptionAlgorithm(let rhs)):
            lhs == rhs
        case (.unsupportedSignature(_), .unsupportedSignature(_)):
            true
        case (.malformedSignature(let lhs), .malformedSignature(let rhs)):
            lhs == rhs
        case (.validationFailed(let lhs), .validationFailed(let rhs)):
            lhs == rhs
        case (.underlyingError(let lhs), .underlyingError(let rhs)):
            (lhs as NSError) == (rhs as NSError)
        default: false
        }
    }
}
