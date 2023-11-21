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
import OktaOAuth2

enum UserPasswordError: Error {
    case missingUsername
    case missingPassword
    case invalidDomain
}

extension UserPasswordSignIn {
    func promptUsername() throws -> String {
        if let username {
            return username
        }
        
        print("Username: ", terminator: "")
        guard let username = readLine(strippingNewline: true) else {
            throw UserPasswordError.missingUsername
        }
        return username
    }
    
    func promptPassword() throws -> String {
        if let password {
            return password
        }
        
        print("Password: ", terminator: "")
        let password = String(cString: getpass(""))
        if password.isEmpty {
            throw UserPasswordError.missingPassword
        }
        return password
    }
    
    func createFlow() throws -> ResourceOwnerFlow {
        guard let issuerUrl = URL(string: issuer) else {
            throw UserPasswordError.invalidDomain
        }
        
        let flow = ResourceOwnerFlow(issuer: issuerUrl,
                                     clientId: clientId,
                                     scopes: scopes)
        return flow
    }
}

func printUserInfo(using token: Token) {
    if let idToken = token.idToken {
        print("""
        Name: \(idToken.name ?? "N/A")
        Locale: \(idToken.userLocale?.identifier ?? "N/A")
        Timezone: \(idToken.timeZone?.identifier ?? "N/A")
        
        Username: \(idToken.preferredUsername ?? "N/A")
        User ID: \(idToken.subject ?? "N/A")
        """)
    } else {
        print("No ID token returned.")
    }
}
