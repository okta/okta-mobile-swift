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
import CryptoSupport

#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

extension Crypto.CryptoKitProvider {
    final class AESGCMCryptor: Crypto.EncryptionProvider, Crypto.DecryptionProvider {
        let algorithm: Crypto.EncryptionAlgorithm
        private let key: SymmetricKey
        
        init(algorithm: Crypto.EncryptionAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: SymmetricKey.self)
        }
        
        func encrypt(data: any DataProtocol, encryptionContext: (any DataProtocol)? = nil) async throws -> any Crypto.EncryptedData {
            let gcmNonce: AES.GCM.Nonce?
            if let nonce = encryptionContext {
                gcmNonce = try .init(data: nonce)
            } else {
                gcmNonce = nil
            }
            
            return try AES.GCM.seal(data, using: key, nonce: gcmNonce)
        }
        
        func encrypt(data: any DataProtocol) async throws -> any Crypto.EncryptedData {
            return try AES.GCM.seal(data, using: key)
        }
        
        func decrypt(data: any Crypto.EncryptedData) async throws -> Data {
            let sealedBox = try AES.GCM.SealedBox(data: data)
            return try AES.GCM.open(sealedBox, using: key)
        }
        
        func decrypt(data: any DataProtocol, encryptionContext: any DataProtocol) async throws -> Data {
            throw CryptoError.unsupported
        }

        func decrypt(data: any DataProtocol) async throws -> Data {
            try await decrypt(data: try AES.GCM.SealedBox(combined: data))
        }
    }
}

#if canImport(Crypto)
import _CryptoExtras
extension Crypto {
    public struct AESCBCEncryptedBox: Sendable, Crypto.EncryptedData {
        public let ciphertext: Data
        public let encryptionContext: Data
        public var rawRepresentation: Data? { nil }

        public init(ciphertext: Data, encryptionContext: Data) {
            self.ciphertext = ciphertext
            self.encryptionContext = encryptionContext
        }
    }
}

extension Crypto.CryptoKitProvider {
    final class AESCBCCryptor: Crypto.EncryptionProvider, Crypto.DecryptionProvider {
        let algorithm: Crypto.EncryptionAlgorithm
        private let key: SymmetricKey

        init(algorithm: Crypto.EncryptionAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: SymmetricKey.self)
        }
        
        func encrypt(data: any DataProtocol, encryptionContext: (any DataProtocol)? = nil) async throws -> any Crypto.EncryptedData {
            let iv: AES._CBC.IV
            if let encryptionContext {
                iv = try AES._CBC.IV(ivBytes: Array(encryptionContext))
            } else {
                iv = .init()
            }

            let resultData = try AES._CBC.encrypt(data, using: key, iv: iv)
            return Crypto.AESCBCEncryptedBox(ciphertext: resultData, encryptionContext: Data(iv))
        }

        func encrypt(data: any DataProtocol) async throws -> any CryptoSupport.Crypto.EncryptedData {
            try await encrypt(data: data, encryptionContext: nil)
        }

        func decrypt(data: any DataProtocol, encryptionContext: any DataProtocol) async throws -> Data {
            let iv = try AES._CBC.IV(ivBytes: Array(encryptionContext))

            return try AES._CBC.decrypt(data,
                            using: key,
                            iv: iv)
        }

        func decrypt(data: any CryptoSupport.Crypto.EncryptedData) async throws -> Data {
            guard let data = data as? Crypto.AESCBCEncryptedBox else {
                throw CryptoError.encryptedDataMissing
            }

            return try await decrypt(data: data.ciphertext, encryptionContext: data.encryptionContext)
        }

        func decrypt(data: any DataProtocol) async throws -> Data {
            throw CryptoError.encryptedDataMissing
        }
    }
}
#endif
