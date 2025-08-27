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
import Testing
import CommonSupport
import CryptoSupport
@testable import _CryptoKitSupport

#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

@Suite("AES GCM Encryption Provider")
struct EncryptionProviderAESGCMTests {
    @Test("AES GCM returning a sealed box")
    func AESGCMEncryptionSealedBox() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let encryptor = try await provider.encryptor(for: .aesGCM, with: key)
        let decryptor = try await provider.decryptor(for: .aesGCM, with: key)

        let dataToEncrypt = Data("Hello, world!".utf8)
        
        let sealedBox = try await encryptor.encrypt(data: dataToEncrypt, encryptionContext: nil)
        
        let decrypted = try await decryptor.decrypt(data: sealedBox)
        #expect(decrypted == dataToEncrypt)
        
        let decryptedData: Data = try await decryptor.decrypt(data: sealedBox)
        #expect(decryptedData == dataToEncrypt)
    }

    @Test("AES GCM returning combined data")
    func AESGCMEncryptionData() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let encryptor = try await provider.encryptor(for: .aesGCM, with: key)
        let decryptor = try await provider.decryptor(for: .aesGCM, with: key)

        let dataToEncrypt = Data("Hello, world!".utf8)
        
        let encryptedData: Data = try await encryptor.encrypt(data: dataToEncrypt)
        
        let decrypted = try await decryptor.decrypt(data: encryptedData)
        #expect(decrypted == dataToEncrypt)
    }
}
