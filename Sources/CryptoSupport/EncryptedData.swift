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
    /// A type of container for the result of an encryption operation.
    ///
    /// This structure bundles the ciphertext with the other data required
    /// to authenticate and decrypt the message securely.
    public protocol EncryptedData: Sendable {
        /// The encrypted data.
        var ciphertext: Data { get }
        
        /// The nonce or Initialization Vector used during encryption.
        var encryptionContext: Data { get }
        
        /// Optional data representation that combines the various properties together into a single value.
        var rawRepresentation: Data? { get }
    }
    
    /// A type of encrypted data container that can be used for GCM algorithms.
    public protocol GCMEncryptedData: EncryptedData {
        /// A tag produced during encryption that is used to authenticate the message.
        var tag: Data { get }
    }
}
