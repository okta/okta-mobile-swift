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

struct ClientConfiguration {
    private static let issuerKey = "issuerUrl"
    private static let clientIdKey = "clientId"
    private static let redirectUriKey = "redirectUrl"
    
    let clientId: String
    let issuer: String
    let redirectUri: String
    let shouldSave: Bool
    
    static var launchConfiguration: ClientConfiguration? {
        var issuer: String?
        var clientId: String?
        var redirectUri: String?
        var key: String?
        for argument in CommandLine.arguments {
            switch argument {
            case "--issuer": fallthrough
            case "--redirectUri": fallthrough
            case "--clientId":
                key = argument
            default:
                switch key {
                case "--issuer": issuer = argument
                case "--redirectUri": redirectUri = argument
                case "--clientId": clientId = argument
                default: break
                }
                key = nil
            }
        }

        guard issuer != nil,
              clientId != nil,
              redirectUri != nil else { return nil }
        return ClientConfiguration(clientId: clientId!, issuer: issuer!, redirectUri: redirectUri!, shouldSave: false)
    }
    
    static var userDefaults: ClientConfiguration? {
        let defaults = UserDefaults.standard
        let environment = ProcessInfo.processInfo.environment
        guard let issuer = defaults.string(forKey: issuerKey) ?? ((environment["ISSUER_DOMAIN"] != "") ? "https://\(environment["ISSUER_DOMAIN"]!)" : nil),
              let clientId = defaults.string(forKey: clientIdKey) ?? environment["CLIENT_ID"],
              let redirectUri = defaults.string(forKey: redirectUriKey) ?? environment["REDIRECT_URI"] else
        {
            return nil
        }
        
        return ClientConfiguration(clientId: clientId, issuer: issuer, redirectUri: redirectUri, shouldSave: false)
    }
    
    func save() {
        guard shouldSave else { return }
        
        let defaults = UserDefaults.standard
        defaults.setValue(issuer, forKey: type(of: self).issuerKey)
        defaults.setValue(clientId, forKey: type(of: self).clientIdKey)
        defaults.setValue(redirectUri, forKey: type(of: self).redirectUriKey)
        defaults.synchronize()
    }
}
