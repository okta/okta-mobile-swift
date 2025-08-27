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
import CommonSupport

public struct Crypto {
    /// Cryptographic hash functions.
    public enum HashFunction: Sendable, Hashable, Equatable {
        case sha256
        case sha384
        case sha512
    }

    /// An enum representing a primitive signing operation.
    public enum SigningAlgorithm: Sendable, Hashable, Equatable, CryptoAlgorithm {
        case hmac(hashFunction: HashFunction)
        case rsa(padding: RSAPadding, hashFunction: HashFunction)
        case ecdsa(hashFunction: HashFunction)
        case eddsa

        /// Padding schemes for RSA signing.
        public enum RSAPadding: Sendable, Hashable, Equatable {
            case pkcs1v1_5
            case pss
        }
    }

    /// An enum representing a primitive key-wrapping (key management) operation.
    public enum KeyWrappingPrimitive: Sendable, Hashable, Equatable {
        case rsaOAEP(hashFunction: HashFunction)
        case aesKeyWrap
        case ecdh
    }

    /// An enum representing a primitive content encryption operation.
    public enum EncryptionAlgorithm: Sendable, Hashable, Equatable, CryptoAlgorithm {
        case aesGCM
        case aesCBC_HMAC(hashFunction: HashFunction)
    }
    
    public static func sign(data: any DataProtocol,
                            using algorithm: Crypto.SigningAlgorithm,
                            with key: any Crypto.Key) async throws -> any Crypto.Signature
    {
        try await Crypto.providers
            .providerFactory
            .signatory(for: algorithm, with: key)
            .sign(data: data)
    }
    
    public static func verify(signature: any Crypto.Signature,
                              for data: any DataProtocol,
                              using algorithm: Crypto.SigningAlgorithm,
                              with key: any Crypto.Key) async throws
    {
        try await Crypto.providers
            .providerFactory
            .verifier(for: algorithm, with: key)
            .verify(signature: signature, for: data)
    }
    
    public static func encrypt(data: any DataProtocol,
                               using algorithm: Crypto.EncryptionAlgorithm,
                               with key: any Crypto.Key,
                               encryptionContext: (any DataProtocol)? = nil) async throws -> any EncryptedData
    {
        let encryptor = try await Crypto.providers
            .providerFactory
            .encryptor(for: algorithm, with: key)
        
        if let encryptionContext {
            return try await encryptor.encrypt(data: data, encryptionContext: encryptionContext)
        } else {
            return try await encryptor.encrypt(data: data)
        }
    }
    
    public static func decrypt(data: any EncryptedData,
                               using algorithm: Crypto.EncryptionAlgorithm,
                               with key: any Crypto.Key) async throws -> Data
    {
        try await Crypto.providers
            .providerFactory
            .decryptor(for: algorithm, with: key)
            .decrypt(data: data)
    }

    public static func decrypt(data: any DataProtocol,
                               using algorithm: Crypto.EncryptionAlgorithm,
                               with key: any Crypto.Key) async throws -> Data
    {
        try await Crypto.providers
            .providerFactory
            .decryptor(for: algorithm, with: key)
            .decrypt(data: data)
    }

    public static func decrypt(data: any DataProtocol,
                               encryptionContext: any DataProtocol,
                               using algorithm: Crypto.EncryptionAlgorithm,
                               with key: any Crypto.Key) async throws -> Data
    {
        try await Crypto.providers
            .providerFactory
            .decryptor(for: algorithm, with: key)
            .decrypt(data: data, encryptionContext: encryptionContext)
    }
}

package protocol CryptoAlgorithm: Sendable, Hashable, Equatable {}

extension Crypto {
    @TaskLocal static var providers: ProviderRegistry = ProviderRegistry()
    
    final class ProviderRegistry: Sendable {
        init(providerFactory: any Crypto.ProviderFactory = ProviderRegistry.defaultCryptoProvider()) {
            _providerFactory = providerFactory
        }
        
        var providerFactory: any Crypto.ProviderFactory {
            get {
                lock.withLock { _providerFactory }
            }
            set {
                lock.withLock { _providerFactory = newValue }
            }
        }
        
        static func defaultCryptoProvider() -> any Crypto.ProviderFactory {
            MockCryptoProviderFactory()
        }
        
        private let lock = Lock()
        nonisolated(unsafe) private var _providerFactory: (any Crypto.ProviderFactory)
    }
}

final class MockCryptoProviderFactory: Crypto.ProviderFactory {
    func signatory(for algorithm: Crypto.SigningAlgorithm,
                   with key: any Crypto.KeyConvertible) throws -> any Crypto.SignatoryProvider
    {
        Signatory(algorithm: algorithm)
    }
    
    func verifier(for algorithm: Crypto.SigningAlgorithm,
                  with key: any Crypto.KeyConvertible) throws -> any Crypto.SignatureVerificationProvider
    {
        SignatureVerification(algorithm: algorithm)
    }
    
    func encryptor(for algorithm: Crypto.EncryptionAlgorithm,
                   with key: any Crypto.KeyConvertible) throws -> any Crypto.EncryptionProvider
    {
        Encryption(algorithm: algorithm)
    }
    
    func decryptor(for algorithm: Crypto.EncryptionAlgorithm,
                   with key: any Crypto.KeyConvertible) throws -> any Crypto.DecryptionProvider
    {
        Decryption(algorithm: algorithm)
    }
    
    struct Signatory: Crypto.SignatoryProvider {
        let algorithm: Crypto.SigningAlgorithm
        
        func sign(data: any DataProtocol) throws -> any Crypto.Signature {
            throw CryptoError.unsupported
        }
    }
    
    struct SignatureVerification: Crypto.SignatureVerificationProvider {
        let algorithm: Crypto.SigningAlgorithm
        
        func verify<T>(signature: T, for data: any DataProtocol) throws {
            throw CryptoError.unsupported
        }
    }
    
    struct Encryption: Crypto.EncryptionProvider {
        let algorithm: Crypto.EncryptionAlgorithm
        
        func encrypt(data: any DataProtocol, encryptionContext: (any DataProtocol)?) async throws -> any Crypto.EncryptedData {
            throw CryptoError.unsupported
        }

        func encrypt(data: any DataProtocol) async throws -> any Crypto.EncryptedData {
            throw CryptoError.unsupported
        }
    }

    struct Decryption: Crypto.DecryptionProvider {
        let algorithm: Crypto.EncryptionAlgorithm
        
        func decrypt(data: any Crypto.EncryptedData) throws -> Data {
            throw CryptoError.unsupported
        }

        func decrypt(data: any DataProtocol) async throws -> Data {
            throw CryptoError.unsupported
        }
        
        func decrypt(data: any DataProtocol, encryptionContext: any DataProtocol) async throws -> Data {
            throw CryptoError.unsupported
        }
    }
}
