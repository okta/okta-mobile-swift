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
    public protocol Convertible: Sendable {
        func convert<T>(to type: T.Type) throws -> T
    }

    public protocol KeyConvertible: Convertible {}

    /// A base protocol for all cryptographic keys.
    public protocol Key: KeyConvertible, Sendable, RawRepresentable where RawValue == Data {}

    /// A protocol representing a key used for symmetric-key cryptography (e.g., HMAC).
    public protocol SymmetricKey: Key { }
    
    /// A protocol representing a key used for asymmetric-key cryptography (e.g., public/private key).
    public protocol AsymmetricKey: Key { }
    
        /// A protocol representing an asymmetric private key used for signing or decryption.
    public protocol PrivateKey: AsymmetricKey {
        associatedtype PublicKeyType: PublicKey
        
        /// The corresponding public key for this private key.
        var publicKey: PublicKeyType { get }
    }
    
    /// A protocol representing an asymmetric public key used for verification or encryption.
    public protocol PublicKey: AsymmetricKey { }
    
    /// A type that represents a cryptographic signature.
    public protocol Signature: Sendable {
        /// The raw data representation of the signature.
        var rawRepresentation: Data { get throws }
    }
}
