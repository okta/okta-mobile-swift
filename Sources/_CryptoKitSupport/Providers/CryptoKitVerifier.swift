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
    final class ECDSAVerifier<KeyType: ECDSAVerifyingKey>: Crypto.SignatureVerificationProvider {
        let algorithm: Crypto.SigningAlgorithm
        private let key: KeyType
        private let hashFunction: any HashFunction.Type

        init(algorithm: Crypto.SigningAlgorithm, key: any Crypto.KeyConvertible) throws {
            guard case let .ecdsa(hashFunction) = algorithm else {
                throw CryptoError.unsupportedSigningAlgorithm(algorithm)
            }

            self.algorithm = algorithm
            self.hashFunction = hashFunction.hashFunction
            self.key = try key.convert(to: KeyType.self)
        }
        
        @inlinable
        func verify(signature: any Crypto.Signature, for data: any DataProtocol) async throws {
            if let signature = signature as? KeyType.SignatureType {
                try _verify(signature: signature, for: data)
            } else {
                try _verify(signature: try .init(rawRepresentation: try signature.rawRepresentation), for: data)
            }
        }

        @inlinable
        func _verify(signature: KeyType.SignatureType, for data: any DataProtocol) throws {
            guard key.isValidSignature(signature, for: hashFunction.hash(data: data))
            else {
                throw CryptoError.validationFailed()
            }
        }
    }

    final class EdDSAVerifier: Crypto.SignatureVerificationProvider {
        let algorithm: Crypto.SigningAlgorithm
        private let key: Curve25519.Signing.PublicKey

        init(algorithm: Crypto.SigningAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: Curve25519.Signing.PublicKey.self)
        }
        
        @inlinable
        func verify(signature: any Crypto.Signature, for data: any DataProtocol) throws {
            if let signature = signature as? Data {
                try _verify(signature: signature, for: data)
            } else {
                try _verify(signature: try signature.rawRepresentation, for: data)
            }
        }

        func _verify(signature: Data, for data: any DataProtocol) throws {
            guard key.isValidSignature(signature, for: data) else {
                throw CryptoError.validationFailed(nil)
            }
        }
    }
}
