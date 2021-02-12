/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct TestCredentials {
    enum Scenario {
        case passcode, mfasop
        
        internal var prefix: String {
            switch self {
            case .passcode: return "PASSCODE"
            case .mfasop: return "MFASOP"
            }
        }
        
        var usernameKey: String {
            return "\(prefix)_USERNAME"
        }

        var passwordKey: String {
            return "\(prefix)_PASSWORD"
        }
    }
    let username: String
    let password: String
    let clientId: String
    let issuer: String
    let redirectUri: String
    var issuerUrl: String {
        return "https://\(issuer)/oauth2/default"
    }

    init?(with scenario: Scenario) {
        let env = ProcessInfo.processInfo.environment
        guard let clientId = env["CLIENT_ID"],
              let issuer = env["ISSUER_DOMAIN"],
              let redirectUri = env["REDIRECT_URI"],
              let username = env[scenario.usernameKey],
              let password = env[scenario.passwordKey] else
        {
            return nil
        }
        
        guard clientId != "",
              issuer != "",
              redirectUri != "",
              username != "",
              password != "" else
        {
            return nil
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.redirectUri = redirectUri
        self.username = username
        self.password = password
    }
}
