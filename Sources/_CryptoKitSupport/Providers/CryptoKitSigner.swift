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
    final class HMACSigner<H: HashFunction>: Crypto.SignatoryProvider, Crypto.SignatureVerificationProvider {
        let algorithm: Crypto.SigningAlgorithm
        private let key: SymmetricKey
        private let signingType: HMAC<H>.Type

        init(algorithm: Crypto.SigningAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: SymmetricKey.self)
            self.signingType = HMAC<H>.self
        }

        func sign(data: any DataProtocol) throws -> any Crypto.Signature {
            signingType.authenticationCode(for: data, using: key)
        }
        
        @inlinable
        func verify(signature: any Crypto.Signature, for data: any DataProtocol) throws {
            if let mac = signature as? HMAC<H>.MAC {
                try verify(mac: mac, for: data)
            } else {
                try verify(bytes: try signature.rawRepresentation, for: data)
            }
        }

        @inlinable
        func verify(mac: HMAC<H>.MAC, for data: any DataProtocol) throws {
            guard signingType.isValidAuthenticationCode(mac,
                                                  authenticating: data,
                                                  using: key)
            else {
                throw CryptoError.validationFailed()
            }
        }
        
        @inlinable
        func verify(bytes: any ContiguousBytes, for data: any DataProtocol) throws {
            guard signingType.isValidAuthenticationCode(bytes,
                                                        authenticating: data,
                                                        using: key)
            else {
                throw CryptoError.validationFailed()
            }
        }
    }

    final class ECDSASigner<KeyType: ECDSASigningKey>: Crypto.SignatoryProvider {
        let algorithm: Crypto.SigningAlgorithm
        private let key: KeyType

        init(algorithm: Crypto.SigningAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: KeyType.self)
        }
        
        func sign(data: any DataProtocol) throws -> any Crypto.Signature {
            return try key.signature(for: data)
        }
    }

    final class EdDSASigner: Crypto.SignatoryProvider {
        let algorithm: Crypto.SigningAlgorithm
        private let key: Curve25519.Signing.PrivateKey

        init(algorithm: Crypto.SigningAlgorithm, key: any Crypto.KeyConvertible) throws {
            self.algorithm = algorithm
            self.key = try key.convert(to: Curve25519.Signing.PrivateKey.self)
        }
        
        func sign(data: any DataProtocol) throws -> any Crypto.Signature {
            return try key.signature(for: data)
        }
    }
}
