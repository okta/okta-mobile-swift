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
private let cryptoExtrasAvailable = false
#elseif canImport(Crypto)
import Crypto
private let cryptoExtrasAvailable = true
#endif

@Suite("AES CBC Encryption Provider", .enabled(if: cryptoExtrasAvailable))
struct EncryptionProviderAESCBCTests {
    @Test("AES CBC HMAC SHA256 returning a sealed box")
    func AESCBCHMACSHA256EncryptionSealedBox() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let encryptor = try await provider.encryptor(for: .aesCBC_HMAC(hashFunction: .sha256), with: key)
        let decryptor = try await provider.decryptor(for: .aesCBC_HMAC(hashFunction: .sha256), with: key)

        let dataToEncrypt = Data("Hello, world!".utf8)
        
        let sealedBox = try await encryptor.encrypt(data: dataToEncrypt, encryptionContext: nil)
        
        let decrypted = try await decryptor.decrypt(data: sealedBox)
        #expect(decrypted == dataToEncrypt)
        
        let decryptedData: Data = try await decryptor.decrypt(data: sealedBox)
        #expect(decryptedData == dataToEncrypt)
    }

    @Test("AES CBC HMAC SHA384 returning a sealed box")
    func AESCBCHMACSHA384EncryptionSealedBox() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let encryptor = try await provider.encryptor(for: .aesCBC_HMAC(hashFunction: .sha384), with: key)
        let decryptor = try await provider.decryptor(for: .aesCBC_HMAC(hashFunction: .sha384), with: key)

        let dataToEncrypt = Data("Hello, world!".utf8)
        
        let sealedBox = try await encryptor.encrypt(data: dataToEncrypt, encryptionContext: nil)
        
        let decrypted = try await decryptor.decrypt(data: sealedBox)
        #expect(decrypted == dataToEncrypt)
        
        let decryptedData: Data = try await decryptor.decrypt(data: sealedBox)
        #expect(decryptedData == dataToEncrypt)
    }

    @Test("AES CBC HMAC SHA512 returning a sealed box")
    func AESCBCHMACSHA512EncryptionSealedBox() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let encryptor = try await provider.encryptor(for: .aesCBC_HMAC(hashFunction: .sha512), with: key)
        let decryptor = try await provider.decryptor(for: .aesCBC_HMAC(hashFunction: .sha512), with: key)

        let dataToEncrypt = Data("Hello, world!".utf8)
        
        let sealedBox = try await encryptor.encrypt(data: dataToEncrypt, encryptionContext: nil)
        
        let decrypted = try await decryptor.decrypt(data: sealedBox)
        #expect(decrypted == dataToEncrypt)
        
        let decryptedData: Data = try await decryptor.decrypt(data: sealedBox)
        #expect(decryptedData == dataToEncrypt)
    }
}
