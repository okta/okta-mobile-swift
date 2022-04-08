//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension JWK {
    /// Attempts to verify the given token, using the appropriate signing algorithm described.
    /// - Parameter token: The ``JWT`` token to verify.
    /// - Returns: `true` if the token is properly signed.
    public func verify(token: JWT) throws -> Bool {
        #if canImport(CommonCrypto)
        guard let algorithm = algorithm else {
            throw JWTError.invalidSigningAlgorithm
        }
        
        let publicKey = try publicKey()
        
        let components = token.rawValue.components(separatedBy: ".")
        guard let data = components[0...1].joined(separator: ".").data(using: .ascii),
              let signature = Data(base64Encoded: components[2].base64URLDecoded)
        else {
            throw JWTError.badTokenStructure
        }

        if #available(iOS 10.0, macCatalyst 13.0, tvOS 10.0, watchOS 3.0, macOS 10.12, *) {
            guard let algorithm = algorithm.secKeyAlgorithm
            else {
                throw JWTError.invalidSigningAlgorithm
            }
            
            return SecKeyVerifySignature(publicKey,
                                         algorithm,
                                         data as NSData,
                                         signature as NSData,
                                         nil)
        }
        
        #if os(iOS) || os(tvOS) || os(watchOS)
        if #available(iOS 2.0, macCatalyst 13.0, tvOS 9.0, watchOS 2.0, *) {
            guard let padding = algorithm.secPadding,
                  let digest = algorithm.digest(data: data)
            else {
                throw JWTError.invalidSigningAlgorithm
            }
            
            var status: OSStatus = noErr
            digest.withUnsafeBytes { (digestBytes: UnsafeRawBufferPointer) in
                signature.withUnsafeBytes { (signatureBytes: UnsafeRawBufferPointer) in
                    // swiftlint:disable force_unwrapping
                    let digestPtr = digestBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    let signaturePtr = signatureBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    // swiftlint:enable force_unwrapping
                    status = SecKeyRawVerify(publicKey,
                                             padding,
                                             digestPtr,
                                             digest.count,
                                             signaturePtr,
                                             signature.count)
                }
            }
            
            switch status {
            case noErr:
                return true
            default:
                return false
            }
        }
        #endif
        #endif
        
        throw JWTError.signatureVerificationUnavailable
    }
}
