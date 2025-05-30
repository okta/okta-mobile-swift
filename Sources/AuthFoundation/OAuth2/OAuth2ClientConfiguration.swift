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

extension OAuth2Client {
    public enum PropertyListConfigurationError: Error {
        case defaultPropertyListNotFound
        case invalidPropertyList(url: URL)
        case cannotParsePropertyList(_ error: (any Error)?)
        case missingConfigurationValues
        case invalidConfiguration(name: String, value: String?)
    }
    
    /// Utility struct used internally to process `Okta.plist` and other similar client configuration files.
    ///
    /// > Important: This struct is intended for internal use, and may be subject to change.
    public struct PropertyListConfiguration {
        private static let ignoreAdditionalKeys: Set<String> = ["issuer", "issuer_url", "client_id", "scope", "scopes", "redirect_uri", "logout_redirect_uri", "client_secret"]
        
        /// The client issuer URL, defined in the "issuer" key.
        public var issuerURL: URL
        
        /// The client ID, defined in the "clientId" key.
        public var clientId: String
        
        /// The client scopes, defined in the "scopes" key.
        public var scope: [String]
        
        /// The client's redirect URI, if one is applicable, defined in the "redirectUri" key.
        public var redirectUri: URL?
        
        /// The client's logout redirect URI, if one is applicable, defined in the "logoutRedirectUri" key.
        public var logoutRedirectUri: URL?
        
        /// The form of client authentication desired from the configuration.
        public var authentication: OAuth2Client.ClientAuthentication
        
        /// Additional parameters defined by the developer within the property list.
        public var additionalParameters: [String: any APIRequestArgument]?
        
        /// Default initializer that reads the `Okta.plist` file from the application's main bundle.
        public init() throws {
            guard let file = Bundle.main.url(forResource: "Okta", withExtension: "plist") else {
                throw PropertyListConfigurationError.defaultPropertyListNotFound
            }
            
            try self.init(plist: file)
        }
        
        /// Initializer that reads the supplied file URL.
        /// - Parameter fileURL: File URL to the client configuration property list.
        public init(plist fileURL: URL) throws {
            guard fileURL.isFileURL else {
                throw PropertyListConfigurationError.invalidPropertyList(url: fileURL)
            }
            
            let plistContent: Any
            do {
                let data = try Data(contentsOf: fileURL)
                plistContent = try PropertyListSerialization.propertyList(from: data,
                                                                          options: [],
                                                                          format: nil)
            } catch {
                throw PropertyListConfigurationError.cannotParsePropertyList(error)
            }
            
            guard let rawDict = plistContent as? [String: String] else {
                throw PropertyListConfigurationError.cannotParsePropertyList(nil)
            }
            
            let dict = rawDict.map(by: \.snakeCase)
            guard let clientId = dict["client_id"],
                  !clientId.isEmpty,
                  let issuer = dict.value("issuer", or: "issuer_url"),
                  let issuerUrl = URL(string: issuer),
                  let scope = dict.value("scope", or: "scopes")?.whitespaceSeparated,
                  !scope.isEmpty
            else {
                throw PropertyListConfigurationError.missingConfigurationValues
            }
            
            let redirectUri: URL?
            if let redirectUriString = dict["redirect_uri"] {
                redirectUri = URL(string: redirectUriString)
            } else {
                redirectUri = nil
            }
            
            let logoutRedirectUri: URL?
            if let logoutRedirectUriString = dict["logout_redirect_uri"] {
                logoutRedirectUri = URL(string: logoutRedirectUriString)
            } else {
                logoutRedirectUri = nil
            }
            
            let authentication: OAuth2Client.ClientAuthentication
            if let clientSecret = dict.value("client_secret", or: "clientSecret") {
                authentication = .clientSecret(clientSecret)
            } else {
                authentication = .none
            }
            
            // Filter only additional parameters
            let additionalParameters = rawDict.filter { (key, _) in
                !Self.ignoreAdditionalKeys.contains(key) &&
                !Self.ignoreAdditionalKeys.contains(key.snakeCase)
            }

            self.init(issuerURL: issuerUrl,
                      clientId: clientId,
                      scope: scope,
                      redirectUri: redirectUri,
                      logoutRedirectUri: logoutRedirectUri,
                      authentication: authentication,
                      additionalParameters: additionalParameters.isEmpty ? nil : additionalParameters)
        }
        
        init(issuerURL: URL,
             clientId: String,
             scope: [String],
             redirectUri: URL? = nil,
             logoutRedirectUri: URL? = nil,
             authentication: OAuth2Client.ClientAuthentication = .none,
             additionalParameters: [String: String]? = nil)
        {
            self.issuerURL = issuerURL
            self.clientId = clientId
            self.scope = scope
            self.redirectUri = redirectUri
            self.logoutRedirectUri = logoutRedirectUri
            self.authentication = authentication
            self.additionalParameters = additionalParameters
        }
    }
}
