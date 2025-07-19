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
        enum Key: String, CaseIterable {
            case issuerURL = "issuer_url"
            case clientId = "client_id"
            case scope
            case redirectUri = "redirect_uri"
            case logoutRedirectUri = "logout_redirect_uri"
            case clientSecret = "client_secret"

            var matchingKeys: Set<String> {
                var result: Set<String> = Set([
                    rawValue,
                    rawValue.camelCase,
                    rawValue.pascalCase,
                ])

                switch self {
                case .issuerURL:
                    result.insert("issuer")
                case .scope:
                    result.insert("scopes")
                default: break
                }

                return result
            }

            static let ignoreAdditionalKeys: Set<String> = {
                Set(allCases.flatMap { $0.matchingKeys })
            }()

            init?(rawValue: String) {
                guard let key = Self.allCases.first(where: { $0.matchingKeys.contains(rawValue) })
                else {
                    return nil
                }

                self = key
            }
        }
        
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
            
            guard let rawDict = plistContent as? [String: Any] else {
                throw PropertyListConfigurationError.cannotParsePropertyList(nil)
            }
            
            try self.init(rawDict)
        }

        /// Initializer that reads a dictionary of keys/values.
        /// - Parameter dictionary: Dictionary of property values.
        public init(_ dictionary: [String: Any]) throws {
            let configurationParameters = dictionary.configurationParameters

            guard let clientId = configurationParameters[.clientId] as? String,
                  let issuerUrl = try URL(string: configurationParameters[.issuerURL] as? String),
                  let scopeParameter = configurationParameters[.scope],
                  let scope = scopeParameter as? [String] ?? (scopeParameter as? String)?.whitespaceSeparated
            else {
                throw PropertyListConfigurationError.missingConfigurationValues
            }

            let redirectUri: URL?
            if let redirectUriString = configurationParameters[.redirectUri] as? String {
                redirectUri = URL(string: redirectUriString)
            } else {
                redirectUri = nil
            }
            
            let logoutRedirectUri: URL?
            if let logoutRedirectUriString = configurationParameters[.logoutRedirectUri] as? String {
                logoutRedirectUri = URL(string: logoutRedirectUriString)
            } else {
                logoutRedirectUri = nil
            }
            
            let authentication: OAuth2Client.ClientAuthentication
            if let clientSecret = configurationParameters[.clientSecret] as? String {
                authentication = .clientSecret(clientSecret)
            } else {
                authentication = .none
            }
            
            // Filter only additional parameters
            let additionalParameters = dictionary.additionalParameters

            self.init(issuerURL: issuerUrl,
                      clientId: clientId,
                      scope: scope,
                      redirectUri: redirectUri,
                      logoutRedirectUri: logoutRedirectUri,
                      authentication: authentication,
                      additionalParameters: additionalParameters.isEmpty ? nil : additionalParameters)
        }
        
        /// Initializes the property list configuration using an array of command-line arguments.
        ///
        /// This will attempt to map values that define the configuration keys using the standard command-line long argument notation. For example, the following forms of arguments are supported:
        ///
        /// ``bash
        /// --issuerUrl=https://example.com --client-id=abcd123 --redirect_uri com.example:/ --scopes "openid profile"
        /// ``
        /// - Parameter arguments: Command-line argument array to process.
        @inlinable
        public init(commandLine arguments: [String]) throws {
            var result = [String: String]()
            var currentKey: String?

            for argument in arguments {
                if argument.hasPrefix("--") {
                    let components = argument
                        .dropFirst(2)
                        .components(separatedBy: "=")

                    if components.count == 2,
                       let key = components.first?.replacingOccurrences(of: "-", with: "_"),
                       let value = components.last
                    {
                        result[key] = value
                        continue
                    } else {
                        currentKey = argument
                            .dropFirst(2)
                            .replacingOccurrences(of: "-", with: "_")
                    }
                }

                else if let key = currentKey {
                    result[key] = argument
                    currentKey = nil
                }
            }

            try self.init(result)
        }

        /// Returns a property list configuration from the current running application's `CommandLine.arguments` array, using the ``init(commandLine:)`` initializer.
        @inlinable public static var commandLine: OAuth2Client.PropertyListConfiguration {
            get throws {
                try self.init(commandLine: CommandLine.arguments)
            }
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

fileprivate extension Dictionary where Key == String, Value == Any {
    typealias ProperyKey = OAuth2Client.PropertyListConfiguration.Key

    var configurationParameters: [ProperyKey: Any] {
        var result = [ProperyKey: Value]()
        for (key, value) in self {
            guard let keyName = ProperyKey(rawValue: key) else {
                continue
            }

            if let value = value as? String,
               value.isEmpty
            {
               continue
            }

            else if value is [Any] {
                break
            }

            result[keyName] = value
        }

        return result
    }

    var additionalParameters: [String: String] {
        let ignoreKeys = OAuth2Client.PropertyListConfiguration.Key.ignoreAdditionalKeys

        return filter { !ignoreKeys.contains($0.key) }
            .compactMapValues { $0 as? String }
    }
}
