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

@Suite("ECDSA Signing Provider")
struct SigningProviderECDSATests {
    @Test("ECDSA SHA256")
    func ECDSASHA256SignatureVerifier() async throws {
        let key = P256.Signing.PrivateKey()
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .ecdsa(hashFunction: .sha256),
                                                     with: key)
        let verifier = try await provider.verifier(for: .ecdsa(hashFunction: .sha256),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signature = try await signatory.sign(data: dataToSign)
        #expect(signature is P256.Signing.ECDSASignature)
        try await verifier.verify(signature: signature, for: dataToSign)
        
        let signatureData = try signature.rawRepresentation
        try await verifier.verify(signature: signatureData, for: dataToSign)

        let signatureString = signatureData.base64EncodedString()
        try await verifier.verify(signature: signatureString, for: dataToSign)
    }

    @Test("ECDSA SHA384")
    func ECDSASHA384SignatureVerifier() async throws {
        let key = P384.Signing.PrivateKey()
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .ecdsa(hashFunction: .sha384),
                                                     with: key)
        let verifier = try await provider.verifier(for: .ecdsa(hashFunction: .sha384),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signature = try await signatory.sign(data: dataToSign)
        #expect(signature is P384.Signing.ECDSASignature)
        try await verifier.verify(signature: signature, for: dataToSign)
        
        let signatureData = try signature.rawRepresentation
        try await verifier.verify(signature: signatureData, for: dataToSign)

        let signatureString = signatureData.base64EncodedString()
        try await verifier.verify(signature: signatureString, for: dataToSign)
    }

    @Test("ECDSA SHA512")
    func ECDSASHA512SignatureVerifier() async throws {
        let key = P521.Signing.PrivateKey()
        let provider = Crypto.CryptoKitProvider()
        let signatory = try await provider.signatory(for: .ecdsa(hashFunction: .sha512),
                                                     with: key)
        let verifier = try await provider.verifier(for: .ecdsa(hashFunction: .sha512),
                                                   with: key)

        let dataToSign = Data("Hello, world!".utf8)
        let signature = try await signatory.sign(data: dataToSign)
        #expect(signature is P521.Signing.ECDSASignature)
        try await verifier.verify(signature: signature, for: dataToSign)
        
        let signatureData = try signature.rawRepresentation
        try await verifier.verify(signature: signatureData, for: dataToSign)

        let signatureString = signatureData.base64EncodedString()
        try await verifier.verify(signature: signatureString, for: dataToSign)
    }
}
