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

@Suite("HMAC Signing Provider")
struct SigningProviderHMACTests {
    @Test("HMAC SHA256")
    func HMACSHA256SignatureVerifier() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .hmac(hashFunction: .sha256),
                                                     with: key)
        let verifier = try await provider.verifier(for: .hmac(hashFunction: .sha256),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signedData = try await signatory.sign(data: dataToSign)
        let signedString = try signedData.rawRepresentation.base64EncodedString()
        #expect(signedString == "K5r5LdJZpb7eq4aVItzaiOlvVDSypzDkju7RxGvk4sQ=")

        try await verifier.verify(signature: signedData, for: dataToSign)
    }

    @Test("HMAC SHA384")
    func HMACSHA384SignatureVerifier() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .hmac(hashFunction: .sha384),
                                                     with: key)
        let verifier = try await provider.verifier(for: .hmac(hashFunction: .sha384),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signedData = try await signatory.sign(data: dataToSign)
        let signedString = try signedData.rawRepresentation.base64EncodedString()
        #expect(signedString == "IT4F0gtfAGFi0gzG3udTB0W+Zgk1EFj2Ry6MtOeh4f2g+/ygbmNAc8XKD9JDLox0")

        try await verifier.verify(signature: signedData, for: dataToSign)
    }

    @Test("HMAC SHA512")
    func HMACSHA512SignatureVerifier() async throws {
        let key = "eFkjSA7E/BT+5UvzVw6UDQ=="
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .hmac(hashFunction: .sha512),
                                                     with: key)
        let verifier = try await provider.verifier(for: .hmac(hashFunction: .sha512),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signedData = try await signatory.sign(data: dataToSign)
        let signedString = try signedData.rawRepresentation.base64EncodedString()
        #expect(signedString == "BKgi0KCRHKNeJ37T3FwhAY5rRNYXSUrseEu4Pks3muNTGLxJMvUfEV4Uo8JKkUcMP7X770g9uX4zXaUU1LTBOg==")

        try await verifier.verify(signature: signedData, for: dataToSign)
    }
}
