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
#endif

public struct DefaultTokenHashValidator: TokenHashValidator {
    public enum HashKey: RawRepresentable {
        public typealias RawValue = String
        
        case accessToken
        case deviceSecret
        case other(key: String)

        public var rawValue: String {
            switch self {
            case .accessToken:
                return "at_hash"
            case .deviceSecret:
                return "ds_hash"
            case .other(key: let value):
                return value
            }
        }
        public init?(rawValue: RawValue) {
            switch rawValue {
            case "at_hash":
                self = .accessToken
            case "ds_hash":
                self = .deviceSecret
            default:
                self = .other(key: rawValue)
            }
        }
    }
    
    let hashKey: HashKey
    
    public init(hashKey: HashKey) {
        self.hashKey = hashKey
    }
    
    #if !canImport(CommonCrypto)
    public func validate(_ string: String, idToken: JWT) throws {
        throw JWTError.signatureVerificationUnavailable
    }
    #else
    public func validate(_ string: String, idToken: JWT) throws {
        guard let hashKey: String = idToken.value(for: hashKey.rawValue)
        else {
            return
        }

        let hash: Data
        switch idToken.header.algorithm {
        case .rs256:
            guard let shaHash = string.data(using: .ascii)?.sha256()
            else {
                throw JWTError.cannotGenerateHash
            }
            hash = shaHash

        default:
            throw JWTError.unsupportedAlgorithm(idToken.header.algorithm)
        }

        let leftmostHash = hash[0 ..< hash.count / 2]
        let compareString = leftmostHash.base64URLEncodedString
        guard compareString == hashKey else {
            throw JWTError.signatureInvalid
        }
    }
    #endif
}
