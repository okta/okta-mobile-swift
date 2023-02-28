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
        case cannotParsePropertyList(_ error: Error?)
        case missingConfigurationValues
        case invalidConfiguration(name: String, value: String?)
    }
    
    /// Utility struct used internally to process `Okta.plist` and other similar client configuration files.
    ///
    /// > Important: This struct is intended for internal use, and may be subject to change.
    public struct PropertyListConfiguration {
        /// The client issuer URL, defined in the "issuer" key.
        public let issuer: URL
        
        /// The client ID, defined in the "clientId" key.
        public let clientId: String
        
        /// The client scopes, defined in the "scopes" key.
        public let scopes: String
        
        /// The client's redirect URI, if one is applicable, defined in the "redirectUri" key.
        public let redirectUri: URL?
        
        /// The client's logout redirect URI, if one is applicable, defined in the "logoutRedirectUri" key.
        public let logoutRedirectUri: URL?
        
        /// Additional parameters defined by the developer within the property list.
        public let additionalParameters: [String: String]?
        
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
            
            guard let dict = plistContent as? [String: String] else {
                throw PropertyListConfigurationError.cannotParsePropertyList(nil)
            }
            
            guard let clientId = dict["clientId"],
                  !clientId.isEmpty,
                  let issuer = dict["issuer"],
                  let issuerUrl = URL(string: issuer),
                  let scopes = dict["scopes"],
                  !scopes.isEmpty
            else {
                throw PropertyListConfigurationError.missingConfigurationValues
            }
            
            let redirectUri: URL?
            if let redirectUriString = dict["redirectUri"] {
                redirectUri = URL(string: redirectUriString)
            } else {
                redirectUri = nil
            }
            
            let logoutRedirectUri: URL?
            if let logoutRedirectUriString = dict["logoutRedirectUri"] {
                logoutRedirectUri = URL(string: logoutRedirectUriString)
            } else {
                logoutRedirectUri = nil
            }
            
            // Filter only additional parameters
            let additionalParameters = dict.filter {
                !["clientId", "issuer", "scopes", "redirectUri", "logoutRedirectUri"].contains($0.key)
            }

            self.init(issuer: issuerUrl,
                      clientId: clientId,
                      scopes: scopes,
                      redirectUri: redirectUri,
                      logoutRedirectUri: logoutRedirectUri,
                      additionalParameters: additionalParameters.isEmpty ? nil : additionalParameters)
        }
        
        init(issuer: URL,
             clientId: String,
             scopes: String,
             redirectUri: URL? = nil,
             logoutRedirectUri: URL? = nil,
             additionalParameters: [String: String]? = nil)
        {
            self.issuer = issuer
            self.clientId = clientId
            self.scopes = scopes
            self.redirectUri = redirectUri
            self.logoutRedirectUri = logoutRedirectUri
            self.additionalParameters = additionalParameters
        }
    }
}
