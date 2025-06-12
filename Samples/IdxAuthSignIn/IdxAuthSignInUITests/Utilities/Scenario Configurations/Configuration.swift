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

extension Scenario {
    struct Configuration {
        let clientId: String
        let issuer: String
        let scopes: String
        let redirectUri: String
        let oktaApiKey: String
        let oktaDomain: String
        let a18nApiKey: String

        var issuerUrl: String {
            return "https://\(issuer)/oauth2/default"
        }

        init() throws {
            let env = ProcessInfo.processInfo.environment
            guard let clientId = env["CLIENT_ID"],
                  let issuer = env["ISSUER_DOMAIN"],
                  let scopes = env["SCOPES"],
                  let redirectUri = env["REDIRECT_URI"],
                  let oktaApiKey = env["OKTA_API_KEY"],
                  let oktaDomain = env["OKTA_DOMAIN"],
                  let a18nApiKey = env["A18N_API_KEY"],
                  clientId != "",
                  issuer != "",
                  scopes != "",
                  redirectUri != "",
                  a18nApiKey != "",
                  oktaApiKey != "",
                  oktaDomain != ""
            else {
                throw Error.missingClientCredentials
            }
            
            self.init(clientId: clientId,
                      issuer: issuer,
                      scopes: scopes,
                      redirectUri: redirectUri,
                      oktaApiKey: oktaApiKey,
                      oktaDomain: oktaDomain,
                      a18nApiKey: a18nApiKey)
        }
            
        init(clientId: String,
             issuer: String,
             scopes: String,
             redirectUri: String,
             oktaApiKey: String,
             oktaDomain: String,
             a18nApiKey: String)
        {
            self.clientId = clientId
            self.issuer = issuer
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.a18nApiKey = a18nApiKey
            self.oktaApiKey = oktaApiKey
            self.oktaDomain = oktaDomain
        }
    }
}
