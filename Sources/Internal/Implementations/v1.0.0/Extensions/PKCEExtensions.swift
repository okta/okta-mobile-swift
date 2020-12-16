//
//  PKCE.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation
import CommonCrypto

#if canImport(CryptoKit)
import CryptoKit
#endif

internal extension Data {
    func sha256() -> Data {
        if #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            return Data(SHA256.hash(data: self))
        } else {
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            self.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
            }
            return Data(hash)
        }
    }
    
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

internal extension String {
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
    
    func pkceCodeChallenge() -> String? {
        return data(using: .ascii)?.sha256().base64URLEncodedString()
    }
}
