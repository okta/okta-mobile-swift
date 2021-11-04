/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
import CommonCrypto

#if canImport(CryptoKit)
import CryptoKit
#endif

internal extension Data {
    /// Produces a SHA256 hash of the supplied data.
    /// - Returns: SHA256 representation of the data.
    func sha256() -> Data {
        #if canImport(CryptoKit)
        if #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            return Data(SHA256.hash(data: self))
        } else {
            return commonCryptoSHA256()
        }
        #else
        return commonCryptoSHA256()
        #endif
    }
    
    private func commonCryptoSHA256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    

    /// Encodes the data as a URL-safe Base64 string.
    /// - Returns: Base64 URL-encoded string.
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

internal extension String {
    /// Generates a PKCE code verifier string.
    /// - Returns: PKCE code verifier string, or `nil` if an error occurs.
    static func pkceCodeVerifier() -> String? {
        var data = Data(count: 32)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        if result == errSecSuccess {
            return data.base64URLEncodedString()
        }

        return nil
    }
    
    /// Generates a PKCE code challenge string.
    /// - Returns: PKCE code challenge string, or `nil` if an error occurs.
    func pkceCodeChallenge() -> String? {
        return data(using: .ascii)?.sha256().base64URLEncodedString()
    }
}
