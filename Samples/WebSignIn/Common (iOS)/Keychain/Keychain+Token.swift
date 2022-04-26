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

enum DeviceSSOError: Error {
    case invalidTokenSecret
}

public extension Keychain {
    
    private static let oktaMobileSdkAccessGroup = "com.okta.mobile-sdk.shared"
    
    static func saveDeviceSSO(_ token: Token) throws {
        try [Token.Kind.idToken, Token.Kind.deviceSecret].forEach { kind in
            try token.token(of: kind)
                .flatMap { $0.data(using: .utf8) }
                .map {
                    Keychain.Item(account: "Okta-\(kind.rawValue)",
                                  service: "Okta",
                                  accessGroup: oktaMobileSdkAccessGroup,
                                  value: $0)
                }
                .map{ try $0.save() }
        }
    }
    
    static func get(_ kind: Token.Kind) throws -> String {
        let item = try Keychain
            .Search(account: "Okta-\(kind.rawValue)",
                    service: "Okta",
                    accessGroup: oktaMobileSdkAccessGroup)
            .get()
        
        guard let token = String(data: item.value, encoding: .utf8) else {
            throw DeviceSSOError.invalidTokenSecret
        }
        
        return token
    }
    
    static func deleteTokens() throws {
        try Keychain
            .Search(service: "Okta",
                    accessGroup: oktaMobileSdkAccessGroup)
            .delete()
    }
}
