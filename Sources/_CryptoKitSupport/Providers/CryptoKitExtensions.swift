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

protocol ECDSASigningKey: Sendable {
    associatedtype SignatureType: Crypto.Signature
    init(rawRepresentation: Data) throws
    func signature<D>(for data: D) throws -> SignatureType where D : DataProtocol
}

protocol ECDSAVerifyingKey: Sendable {
    associatedtype SignatureType: ECDSAVerificationSignature
    init(rawRepresentation: Data) throws
    func isValidSignature<D>(_ signature: SignatureType, for digest: D) -> Bool where D : Digest
}

protocol ECDSAVerificationKey: Sendable {
    associatedtype SignatureType: Crypto.Signature
}

protocol ECDSAVerificationSignature: Crypto.Signature {
    init(rawRepresentation: Data) throws
}

// For HMAC signatures (e.g., HMAC-SHA256)
extension HashedAuthenticationCode: Crypto.Signature {
    public var rawRepresentation: Data {
        return Data(self)
    }
}

// For EdDSA signatures, CryptoKit returns raw Data, so make Data itself conform to the Signature protocol.
extension Data: Crypto.Signature {
    public var rawRepresentation: Data { self }
    
    public init(rawRepresentation: Data) throws {
        self = rawRepresentation
    }
}

// MARK: - Symmetric Key Conformance
// ---------------------------------

extension SymmetricKey: @retroactive RawRepresentable {}
extension SymmetricKey: Crypto.SymmetricKey {
    public var rawValue: Data {
        return self.withUnsafeBytes { Data($0) }
    }
    
    public init?(rawValue: Data) {
        self.init(data: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        guard type == SymmetricKey.self else {
            throw CryptoError.unsupportedKey(self)
        }
        return self as! T
    }
}

extension Crypto.HashFunction {
    var hashFunction: any HashFunction.Type {
        switch self {
        case .sha256:
            return SHA256.self
        case .sha384:
            return SHA384.self
        case .sha512:
            return SHA512.self
        }
    }
}

extension Data: Crypto.KeyConvertible {
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is Data.Type:
            return self as! T

        case is SymmetricKey.Type:
            return SymmetricKey(data: self) as! T

        case is P256.Signing.PrivateKey.Type:
            return try P256.Signing.PrivateKey(rawRepresentation: self) as! T
            
        case is P384.Signing.PrivateKey.Type:
            return try P384.Signing.PrivateKey(rawRepresentation: self) as! T
            
        case is P521.Signing.PrivateKey.Type:
            return try P521.Signing.PrivateKey(rawRepresentation: self) as! T

        default:
            throw CryptoError.unsupportedKey(self)
        }
    }
}

extension String: Crypto.KeyConvertible {
    @inlinable
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is String.Type:
            return self as! T

        case is Data.Type:
            guard let data = Data(base64Encoded: Data(utf8))
            else {
                throw CryptoError.unsupportedKey(self)
            }
            return data as! T
            
        default:
            return try convert(to: Data.self).convert(to: T.self)
        }
    }
}

extension String: Crypto.Signature {
    public var rawRepresentation: Data {
        get throws {
            guard let data = Data(base64Encoded: Data(utf8))
            else {
                throw CryptoError.unsupportedKey(self)
            }
            return data
        }
    }
}

// MARK: - swift-crypto extension conformances
// -------------------------------------
#if !canImport(CryptoKit)
extension P256.Signing.ECDSASignature: @unchecked @retroactive Sendable {}
extension P256.Signing.PrivateKey: @unchecked @retroactive Sendable {}
extension P256.Signing.PublicKey: @unchecked @retroactive Sendable {}

extension P384.Signing.ECDSASignature: @unchecked @retroactive Sendable {}
extension P384.Signing.PrivateKey: @unchecked @retroactive Sendable {}
extension P384.Signing.PublicKey: @unchecked @retroactive Sendable {}

extension P521.Signing.ECDSASignature: @unchecked @retroactive Sendable {}
extension P521.Signing.PrivateKey: @unchecked @retroactive Sendable {}
extension P521.Signing.PublicKey: @unchecked @retroactive Sendable {}

extension Curve25519.Signing.PrivateKey: @unchecked @retroactive Sendable {}
extension Curve25519.Signing.PublicKey: @unchecked @retroactive Sendable {}
extension P256.KeyAgreement.PrivateKey: @unchecked @retroactive Sendable {}
extension P256.KeyAgreement.PublicKey: @unchecked @retroactive Sendable {}
extension Curve25519.KeyAgreement.PrivateKey: @unchecked @retroactive Sendable {}
extension Curve25519.KeyAgreement.PublicKey: @unchecked @retroactive Sendable {}

extension SymmetricKey: @unchecked @retroactive Sendable {}
extension HMAC: @unchecked @retroactive Sendable {}
extension HashedAuthenticationCode: @unchecked @retroactive Sendable {}
#endif

// MARK: - ECDSA Signing Key Conformances
// -------------------------------------

// P-256
extension P256.Signing.ECDSASignature: ECDSAVerificationSignature {
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P256.Signing.ECDSASignature.Type:
            return self as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P256.Signing.PrivateKey: @retroactive RawRepresentable {}
extension P256.Signing.PrivateKey: Crypto.PrivateKey, ECDSASigningKey {
    typealias SignatureType = P256.Signing.ECDSASignature

    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P256.Signing.PrivateKey.Type:
            return self as! T
        case is P256.Signing.PublicKey.Type:
            return publicKey as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P256.Signing.PublicKey: @retroactive RawRepresentable {}
extension P256.Signing.PublicKey: Crypto.PublicKey, ECDSAVerifyingKey {
    typealias SignatureType = P256.Signing.ECDSASignature
    
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P256.Signing.PublicKey.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

// P-384
extension P384.Signing.ECDSASignature: ECDSAVerificationSignature {
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P384.Signing.ECDSASignature.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P384.Signing.PrivateKey: @retroactive RawRepresentable {}
extension P384.Signing.PrivateKey: Crypto.PrivateKey, ECDSASigningKey {
    typealias SignatureType = P384.Signing.ECDSASignature
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P384.Signing.PrivateKey.Type:
            return self as! T
        case is P384.Signing.PublicKey.Type:
            return publicKey as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P384.Signing.PublicKey: @retroactive RawRepresentable {}
extension P384.Signing.PublicKey: Crypto.PublicKey, ECDSAVerifyingKey {
    typealias SignatureType = P384.Signing.ECDSASignature
    
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P384.Signing.PublicKey.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

// P-521
extension P521.Signing.ECDSASignature: ECDSAVerificationSignature {
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P521.Signing.ECDSASignature.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P521.Signing.PrivateKey: @retroactive RawRepresentable {}
extension P521.Signing.PrivateKey: Crypto.PrivateKey, ECDSASigningKey {
    typealias SignatureType = P521.Signing.ECDSASignature
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P521.Signing.PrivateKey.Type:
            return self as! T
        case is P521.Signing.PublicKey.Type:
            return publicKey as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension P521.Signing.PublicKey: @retroactive RawRepresentable {}
extension P521.Signing.PublicKey: Crypto.PublicKey, ECDSAVerifyingKey {
    typealias SignatureType = P521.Signing.ECDSASignature
    
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is P521.Signing.PublicKey.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}


// MARK: - EdDSA Signing Key Conformances
// --------------------------------------

extension Curve25519.Signing.PrivateKey: @retroactive RawRepresentable {}
extension Curve25519.Signing.PrivateKey: Crypto.PrivateKey {
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is Curve25519.Signing.PrivateKey.Type:
            return self as! T
        case is Curve25519.Signing.PublicKey.Type:
            return publicKey as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}

extension Curve25519.Signing.PublicKey: @retroactive RawRepresentable {}
extension Curve25519.Signing.PublicKey: Crypto.PublicKey {
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        switch type {
        case is Curve25519.Signing.PublicKey.Type:
            return self as! T
        case is Data.Type:
            return rawRepresentation as! T
        default:
            throw CryptoError.unsupported
        }
    }
}


// MARK: - ECDH Key Agreement Conformances
// ---------------------------------------

// P-256
extension P256.KeyAgreement.PrivateKey: @retroactive RawRepresentable {}
extension P256.KeyAgreement.PrivateKey: Crypto.PrivateKey {
    public var rawValue: Data { self.x963Representation } // Note: x963Representation is standard for EC keys
    public init?(rawValue: Data) {
        try? self.init(x963Representation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        throw CryptoError.unsupported
    }
}

extension P256.KeyAgreement.PublicKey: @retroactive RawRepresentable {}
extension P256.KeyAgreement.PublicKey: Crypto.PublicKey {
    public var rawValue: Data { self.x963Representation }
    public init?(rawValue: Data) {
        try? self.init(x963Representation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        throw CryptoError.unsupported
    }
}

// Curve25519
extension Curve25519.KeyAgreement.PrivateKey: @retroactive RawRepresentable {}
extension Curve25519.KeyAgreement.PrivateKey: Crypto.PrivateKey {
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        throw CryptoError.unsupported
    }
}

extension Curve25519.KeyAgreement.PublicKey: @retroactive RawRepresentable {}
extension Curve25519.KeyAgreement.PublicKey: Crypto.PublicKey {
    public var rawValue: Data { self.rawRepresentation }
    public init?(rawValue: Data) {
        try? self.init(rawRepresentation: rawValue)
    }
    
    public func convert<T>(to type: T.Type) throws -> T {
        throw CryptoError.unsupported
    }
}
