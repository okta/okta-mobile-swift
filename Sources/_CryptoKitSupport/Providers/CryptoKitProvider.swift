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
import CryptoSupport

#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

extension Crypto {
    /// A provider that uses Apple's CryptoKit framework and caches cryptographic objects for performance.
    public actor CryptoKitProvider: Crypto.ProviderFactory {
        
        // MARK: Cache Keys
        private struct CacheKey<Algorithm: CryptoAlgorithm>: Hashable {
            let algorithm: Algorithm
            let key: AnyCryptographicKey
            
            init(algorithm: Algorithm, key: any Crypto.KeyConvertible) throws {
                self.algorithm = algorithm
                self.key = try .init(key)
            }
        }

        // MARK: Caches
        private var signers = [CacheKey<Crypto.SigningAlgorithm>: any Crypto.SignatoryProvider]()
        private var verifiers = [CacheKey<Crypto.SigningAlgorithm>: any Crypto.SignatureVerificationProvider]()
        private var encryptors = [CacheKey<Crypto.EncryptionAlgorithm>: any Crypto.EncryptionProvider]()
        private var decryptors = [CacheKey<Crypto.EncryptionAlgorithm>: any Crypto.DecryptionProvider]()
        
        public init() {}
        
        // MARK: CryptographyProvider Conformance
        
        public func signatory(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any Crypto.SignatoryProvider {
            let cacheKey = try CacheKey(algorithm: algorithm, key: key)
            if let cachedSigner = signers[cacheKey] {
                return cachedSigner
            }
            
            let newSigner: any Crypto.SignatoryProvider
            switch algorithm {
            case .hmac(hashFunction: let hashFunction):
                switch hashFunction {
                case .sha256:
                    newSigner = try HMACSigner<SHA256>(algorithm: algorithm, key: key)
                case .sha384:
                    newSigner = try HMACSigner<SHA384>(algorithm: algorithm, key: key)
                case .sha512:
                    newSigner = try HMACSigner<SHA512>(algorithm: algorithm, key: key)
                }

            case .ecdsa(let hashFunction):
                switch hashFunction {
                case .sha256:
                    newSigner = try ECDSASigner<P256.Signing.PrivateKey>(algorithm: algorithm, key: key)
                case .sha384:
                    newSigner = try ECDSASigner<P384.Signing.PrivateKey>(algorithm: algorithm, key: key)
                case .sha512:
                    newSigner = try ECDSASigner<P521.Signing.PrivateKey>(algorithm: algorithm, key: key)
                }
            
            case .eddsa:
                newSigner = try EdDSASigner(algorithm: algorithm, key: key)

            case .rsa:
                throw CryptoError.unsupportedSigningAlgorithm(algorithm)
            }

            // Store it in the cache.
            signers[cacheKey] = newSigner
            
            return newSigner
        }
        
        public func verifier(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any Crypto.SignatureVerificationProvider {
            let cacheKey = try CacheKey(algorithm: algorithm, key: key)
            if let cachedVerifier = verifiers[cacheKey] {
                return cachedVerifier
            }
            
            let newVerifier: any Crypto.SignatureVerificationProvider
            switch algorithm {
            case .hmac(hashFunction: let hashFunction):
                switch hashFunction {
                case .sha256:
                    newVerifier = try HMACSigner<SHA256>(algorithm: algorithm, key: key)
                case .sha384:
                    newVerifier = try HMACSigner<SHA384>(algorithm: algorithm, key: key)
                case .sha512:
                    newVerifier = try HMACSigner<SHA512>(algorithm: algorithm, key: key)
                }

            case .ecdsa(let hashFunction):
                switch hashFunction {
                case .sha256:
                    newVerifier = try ECDSAVerifier<P256.Signing.PublicKey>(algorithm: algorithm, key: key)
                case .sha384:
                    newVerifier = try ECDSAVerifier<P384.Signing.PublicKey>(algorithm: algorithm, key: key)
                case .sha512:
                    newVerifier = try ECDSAVerifier<P521.Signing.PublicKey>(algorithm: algorithm, key: key)
                }

            case .eddsa:
                newVerifier = try EdDSAVerifier(algorithm: algorithm, key: key)

            case .rsa:
                throw CryptoError.unsupportedSigningAlgorithm(algorithm)
            }
            verifiers[cacheKey] = newVerifier
            return newVerifier
        }
        
        public func encryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any Crypto.EncryptionProvider {
            let cacheKey = try CacheKey(algorithm: algorithm, key: key)

            if let cachedEncryptor = encryptors[cacheKey] {
                return cachedEncryptor
            }
            
            let newEncryptor: any Crypto.EncryptionProvider
            switch algorithm {
            case .aesGCM:
                newEncryptor = try AESGCMCryptor(algorithm: algorithm, key: key)
                
            case .aesCBC_HMAC(_):
            #if canImport(CryptoKit)
                throw CryptoError.unsupportedEncryptionAlgorithm(algorithm)
            #else
                newEncryptor = try AESCBCCryptor(algorithm: algorithm, key: key)
            #endif
            }
            
            encryptors[cacheKey] = newEncryptor
            return newEncryptor
        }
        
        public func decryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) async throws -> any Crypto.DecryptionProvider {
            let cacheKey = try CacheKey(algorithm: algorithm, key: key)

            if let cachedDecryptor = decryptors[cacheKey] {
                return cachedDecryptor
            }
            
            let newDecryptor: any Crypto.DecryptionProvider
            switch algorithm {
            case .aesGCM:
                newDecryptor = try AESGCMCryptor(algorithm: algorithm, key: key)
                
            #if canImport(CryptoKit)
            case .aesCBC_HMAC(_):
                throw CryptoError.unsupportedEncryptionAlgorithm(algorithm)
            #else
            case .aesCBC_HMAC(let hashFunction):
                newDecryptor = try AESCBCCryptor(algorithm: algorithm, key: key)
            #endif
            }

            decryptors[cacheKey] = newDecryptor
            return newDecryptor
        }
    }
}
