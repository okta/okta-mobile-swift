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

struct DefaultTokenHashValidator: TokenHashValidator {
    enum HashKey: String {
        case accessToken = "at_hash"
        case deviceSecret = "ds_hash"
    }
    
    let hashKey: HashKey
    
    #if !canImport(CommonCrypto)
    func validate(_ string: String, idToken: JWT) throws {
        throw JWTError.signatureVerificationUnavailable
    }
    #else
    func validate(_ string: String, idToken: JWT) throws {
        guard let hashKey = idToken.value(String.self, for: hashKey.rawValue)
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
