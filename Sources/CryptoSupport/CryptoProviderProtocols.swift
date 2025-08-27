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

extension Crypto {
    /// A type that provides cryptographic signing and verification services.
    public protocol ProviderFactory: Sendable {
        /// Creates a `Signer` for the given algorithm and key.
        /// - Parameters:
        ///   - algorithm: The signing algorithm to use.
        ///   - key: The key to sign with (must be a private or symmetric key).
        /// - Returns: A configured object that can perform the signing.
        func signatory(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any SignatoryProvider
        
        /// Creates a `Verifier` for the given algorithm and key.
        /// - Parameters:
        ///   - algorithm: The verification algorithm to use.
        ///   - key: The key to verify with (must be a public or symmetric key).
        /// - Returns: A configured object that can perform the verification.
        func verifier(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any SignatureVerificationProvider
        
        /// Creates an `Encryptor` for the given algorithm and key.
        /// - Parameters:
        ///   - algorithm: The encryption algorithm to use.
        ///   - key: The key to encrypt with (can be symmetric or asymmetric public).
        /// - Returns: A configured object that can perform encryption.
        func encryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any EncryptionProvider
        
        /// Creates a `Decryptor` for the given algorithm and key.
        /// - Parameters:
        ///   - algorithm: The decryption algorithm to use.
        ///   - key: The key to decrypt with (can be symmetric or asymmetric private).
        /// - Returns: A configured object that can perform decryption.
        func decryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any DecryptionProvider
    }
    
    /// An object capable of creating a cryptographic signature for given data.
    public protocol SignatoryProvider: Sendable {
        /// The signing algorithm being used.
        var algorithm: Crypto.SigningAlgorithm { get }
        
        /// Creates a signature for the given data.
        /// - Parameter data: The data to sign.
        /// - Returns: The signature as raw `Data`.
        func sign(data: any DataProtocol) async throws -> any Signature
    }
    
    /// An object capable of verifying a cryptographic signature against given data.
    public protocol SignatureVerificationProvider: Sendable {
        /// The signing algorithm being used.
        var algorithm: Crypto.SigningAlgorithm { get }
        
        /// Verifies a signature for the given data.
        /// - Parameters:
        ///   - signature: The signature to check.
        ///   - data: The data that was originally signed.
        /// - Throws: An error if the signature is invalid.
        func verify(signature: any Signature, for data: any DataProtocol) async throws
    }
    
    /// An object capable of encrypting data.
    public protocol EncryptionProvider: Sendable {
        /// The encryption algorithm being used.
        var algorithm: Crypto.EncryptionAlgorithm { get }
        
        /// Encrypts the given plaintext data.
        /// - Parameters:
        ///   - data: The plaintext data to encrypt.
        /// - Returns: An `EncryptedData` object containing the ciphertext and required metadata.
        func encrypt(data: any DataProtocol) async throws -> any EncryptedData

        /// Encrypts the given plaintext data.
        /// - Parameters:
        ///   - data: The plaintext data to encrypt.
        ///   - encryptionContext: The optional context required for the encryption (e.g. nonce, IV, etc).
        /// - Returns: An `EncryptedData` object containing the ciphertext and required metadata.
        func encrypt(data: any DataProtocol, encryptionContext: (any DataProtocol)?) async throws -> any EncryptedData
    }
    
    /// An object capable of decrypting data.
    public protocol DecryptionProvider: Sendable {
        /// The decryption algorithm being used.
        var algorithm: Crypto.EncryptionAlgorithm { get }
        
        /// Decrypts the given encrypted data container.
        /// - Parameter data: The container with the ciphertext, nonce, and authentication tag.
        /// - Returns: The original plaintext `Data`.
        /// - Throws: An error if decryption fails (e.g., due to an invalid authentication tag).
        func decrypt(data: any EncryptedData) async throws -> Data

        /// Decrypts the given encrypted combined data representation.
        /// - Parameter data: The combined raw representation of the encrypted data.
        /// - Returns: The original plaintext `Data`.
        /// - Throws: An error if decryption fails (e.g., due to an invalid authentication tag).
        func decrypt(data: any DataProtocol) async throws -> Data

        /// Decrypts the given encrypted combined data representation.
        /// - Parameters:
        ///   - data: The encrypted data to decrypt.
        ///   - encryptionContext: The context required for the decryption (e.g. IV, etc).
        /// - Returns: The original plaintext `Data`.
        /// - Throws: An error if decryption fails (e.g., due to an invalid authentication tag).
        func decrypt(data: any DataProtocol, encryptionContext: any DataProtocol) async throws -> Data
    }
}

extension Crypto.EncryptionProvider {
    public func encrypt(data: any DataProtocol, encryptionContext: any DataProtocol) async throws -> Data {
        let box: any Crypto.EncryptedData = try await encrypt(data: data, encryptionContext: encryptionContext)
        guard let resultData = box.rawRepresentation else {
            throw CryptoError.encryptedDataMissing
        }
        return resultData
    }

    public func encrypt(data: any DataProtocol) async throws -> Data {
        let box: any Crypto.EncryptedData = try await encrypt(data: data)
        guard let resultData = box.rawRepresentation else {
            throw CryptoError.encryptedDataMissing
        }
        return resultData
    }
}
