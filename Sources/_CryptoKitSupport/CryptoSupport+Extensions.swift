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

extension AES.GCM.SealedBox: @unchecked Sendable {}
#endif

extension AES.GCM.SealedBox: Crypto.GCMEncryptedData {
    public var encryptionContext: Data { Data(nonce) }
    public var rawRepresentation: Data? { combined }
    public init(data: any Crypto.EncryptedData) throws {
        if let data = data as? AES.GCM.SealedBox {
            self = data
        } else if let data = data as? any Crypto.GCMEncryptedData {
            try self.init(nonce: try .init(data: data.encryptionContext),
                          ciphertext: data.ciphertext,
                          tag: data.tag)
        } else {
            throw CryptoError.encryptedDataMissing
        }
    }
}
