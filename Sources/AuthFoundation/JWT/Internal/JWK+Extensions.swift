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

#if canImport(CommonCrypto)
import CommonCrypto

extension JWK.Algorithm {
    @available(iOS 10.0, macCatalyst 13.0, tvOS 10.0, watchOS 3.0, macOS 10.12, *)
    var secKeyAlgorithm: SecKeyAlgorithm? {
        switch self {
        case .rs256:
            return .rsaSignatureMessagePKCS1v15SHA256
        case .rs384:
            return .rsaSignatureMessagePKCS1v15SHA384
        case .rs512:
            return .rsaSignatureMessagePKCS1v15SHA512
        default:
            return nil
        }
    }
    
    var secPadding: SecPadding? {
        switch self {
        case .rs256:
            return .PKCS1SHA256
        case .rs384:
            return .PKCS1SHA384
        case .rs512:
            return .PKCS1SHA512
        default:
            return nil
        }
    }
    
    func digest(data: Data) -> Data? {
        switch self {
        case .rs256:
            var digestBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digestBytes)
            }
            return Data(digestBytes)
        case .rs384:
            var digestBytes = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA384($0.baseAddress, CC_LONG(data.count), &digestBytes)
            }
            return Data(digestBytes)
        case .rs512:
            var digestBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &digestBytes)
            }
            return Data(digestBytes)
        default:
            return nil
        }
    }
}

extension JWK {
    var rsaData: Data? {
        guard let rsaModulus = rsaModulus?.base64URLDecoded,
              let rsaExponent = rsaExponent?.base64URLDecoded,
              let modulusData = Data(base64Encoded: rsaModulus),
              let exponentData = Data(base64Encoded: rsaExponent)
        else {
            return nil
        }

        return Data(modulus: modulusData, exponent: exponentData)
    }

    func publicKey() throws -> SecKey {
        guard let keyData = rsaData else {
            throw JWTError.invalidKey
        }
        
        if #available(iOS 10.0, macCatalyst 13.0, tvOS 10.0, watchOS 3.0, macOS 10.12, *) {
            let keySize = keyData.count * 8
            var errorRef: Unmanaged<CFError>?
            let attributes: [CFString: Any] = [
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits: NSNumber(value: keySize),
                kSecReturnPersistentRef: true
            ]
            
            guard let publicKey: SecKey = SecKeyCreateWithData(keyData as NSData,
                                                               attributes as NSDictionary,
                                                               &errorRef)
            else {
                let error = errorRef?.takeRetainedValue()
                let desc = error != nil ? CFErrorCopyDescription(error) : nil
                let code = error != nil ? CFErrorGetCode(error) : 0
                throw JWTError.cannotCreateKey(code: OSStatus(code),
                                               description: desc as String?)
            }
            
            return publicKey
        } else {
            let persistKey = UnsafeMutablePointer<AnyObject?>(mutating: nil)
            
            let addAttributes: [CFString: Any] = [
                kSecClass: kSecClassKey,
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecValueData: keyData,
                kSecAttrKeyClass: kSecAttrKeyTypeRSA,
                kSecReturnPersistentRef: true,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ]
            
            let addStatus = SecItemAdd(addAttributes as CFDictionary, persistKey)
            guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
                throw JWTError.cannotCreateKey(code: addStatus,
                                                        description: nil)
            }
            
            let copyAttributes: [CFString: Any] = [
                kSecClass: kSecClassKey,
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: kSecAttrKeyTypeRSA,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
                kSecReturnRef: true
            ]
            
            var keyRef: AnyObject?
            let copyStatus = SecItemCopyMatching(copyAttributes as CFDictionary, &keyRef)
            
            guard let publicKey = keyRef else {
                throw JWTError.cannotCreateKey(code: copyStatus,
                                                        description: nil)
            }
            
            // swiftlint:disable force_cast
            return publicKey as! SecKey
            // swiftlint:enable force_cast
        }
    }
}

#endif
