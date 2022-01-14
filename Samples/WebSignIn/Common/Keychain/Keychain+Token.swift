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
import AuthFoundation

public extension Keychain {
    
    private static let oktaMobileSdkAccessGroup = "com.okta.mobile-sdk.shared"
    
    static func save(_ token: Token) throws {
        try [Token.Kind.idToken, Token.Kind.deviceSecret].forEach { kind in
            try token.token(of: kind).flatMap {
                try Keychain.set(key: "Okta-\(kind.rawValue)",
                                 string: $0,
                                 accessGroup: oktaMobileSdkAccessGroup,
                                 accessibility: kSecAttrAccessibleWhenUnlocked)
            }
        }
    }
    
    static func get(_ kind: Token.Kind) throws -> String {
        try Keychain.get(key: "Okta-\(kind.rawValue)", accessGroup: oktaMobileSdkAccessGroup)
    }
    
    static func deleteTokens() throws {
        try [Token.Kind.idToken, Token.Kind.deviceSecret].forEach { kind in
            try Keychain.remove(key: "Okta-\(kind.rawValue)", accessGroup: oktaMobileSdkAccessGroup)
        }
    }
}
