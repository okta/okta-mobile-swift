//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
#endif

#if canImport(CryptoKit)
import CryptoKit
#endif

#if canImport(CommonCrypto)
internal extension Int {
    static let sha56DigestLength = Int(CC_SHA256_DIGEST_LENGTH)
}
#endif

internal extension Data {
    /// Produces a SHA256 hash of the supplied data.
    /// - Returns: SHA256 representation of the data.
    func sha256() -> Data? {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(macOS)
        if #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            return Data(SHA256.hash(data: self))
        } else {
            var hash = [UInt8](repeating: 0, count: Int.sha56DigestLength)
            self.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
            }
            return Data(hash)
        }
        #else
        return nil
        #endif
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
    /// Generates a PKCE code challenge string.
    /// - Returns: PKCE code challenge string, or `nil` if an error occurs.
    func pkceCodeChallenge() -> String? {
        return data(using: .ascii)?.sha256()?.base64URLEncodedString()
    }
}

extension FixedWidthInteger {
    static func random() -> Self {
        return Self.random(in: .min ... .max)
    }

    static func random<T>(using generator: inout T) -> Self
        where T : RandomNumberGenerator
    {
        return Self.random(in: .min ... .max, using: &generator)
    }
}

extension Array where Element: FixedWidthInteger {
    static func random(count: Int) -> [Element] {
        var array: [Element] = .init(repeating: 0, count: count)
        (0 ..< count).forEach { array[$0] = Element.random() }
        return array
    }

    static func random<T>(count: Int, using generator: inout T) -> [Element]
        where T: RandomNumberGenerator
    {
        var array: [Element] = .init(repeating: 0, count: count)
        (0 ..< count).forEach { array[$0] = Element.random() }
        return array
    }
}

extension Array where Element == UInt8 {
    var base64: String {
        Data(self).base64EncodedString()
    }
}
