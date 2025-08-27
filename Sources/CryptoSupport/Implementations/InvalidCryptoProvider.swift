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

extension Crypto {
    /// A provider that uses Apple's CryptoKit framework and caches cryptographic objects for performance.
    public final class InvalidProvider: Crypto.ProviderFactory {
        public init() {}
        
        // MARK: CryptographyProvider Conformance
        
        public func signatory(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) throws -> any Crypto.SignatoryProvider {
            throw CryptoError.unsupportedSigningAlgorithm(algorithm)
        }
        
        public func verifier(for algorithm: Crypto.SigningAlgorithm, with key: any Crypto.KeyConvertible) throws -> any Crypto.SignatureVerificationProvider {
            throw CryptoError.unsupportedSigningAlgorithm(algorithm)
        }
        
        public func encryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) throws -> any Crypto.EncryptionProvider {
            throw CryptoError.unsupportedEncryptionAlgorithm(algorithm)
        }
        
        public func decryptor(for algorithm: Crypto.EncryptionAlgorithm, with key: any Crypto.KeyConvertible) throws -> any Crypto.DecryptionProvider {
            throw CryptoError.unsupportedEncryptionAlgorithm(algorithm)
        }
    }
}
