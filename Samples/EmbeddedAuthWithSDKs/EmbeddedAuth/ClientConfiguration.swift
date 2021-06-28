/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
    private static let scopesKey = "scopes"

    let clientId: String
    let issuer: String
    let redirectUri: String
    let scopes: String
    let shouldSave: Bool
    
    init(clientId: String, issuer: String, redirectUri: String, scopes: String, shouldSave: Bool) throws {
        guard let issuerUrl = URL(string: issuer) else {
            throw ConfigurationError.invalidUrl(name: "issuer")
        }
        
        guard issuerUrl.path.hasPrefix("/oauth2") else {
            throw ConfigurationError.issuerMissingPath
        }
        
        guard clientId.count > 0 else {
            throw ConfigurationError.missingValue(name: "clientId")
        }
        
        guard URL(string: redirectUri) != nil else {
            throw ConfigurationError.invalidUrl(name: "redirectUri")
        }

        let scopeArray = scopes.components(separatedBy: " ")
        guard scopes.count > 0,
              scopeArray.count > 0
        else {
            throw ConfigurationError.missingValue(name: "scopes")
        }
        
        guard scopeArray.contains("openid"),
              scopeArray.contains("profile")
        else {
            throw ConfigurationError.missingRecommendedScopes
        }
        
        self.issuer = issuer
        self.clientId = clientId
        self.scopes = scopes
        self.redirectUri = redirectUri
        self.shouldSave = shouldSave
    }
    
    static var launchConfiguration: ClientConfiguration? {
        let arguments = [
            "--issuer", "-i",
            "--redirectUri", "-r",
            "--scopes", "-s",
            "--clientId", "-c"
        ]
        
        var issuer: String?
        var clientId: String?
        var scopes: String = "openid profile offline_access"
        var redirectUri: String?
        var key: String?
        for argument in CommandLine.arguments {
            if arguments.contains(argument) {
                key = argument
                continue
            }
            
            switch key {
            case "--issuer": fallthrough
            case "-i":
                issuer = argument
                
            case "--redirectUri": fallthrough
            case "-r":
                redirectUri = argument
                
            case "--clientId": fallthrough
            case "-c":
                clientId = argument
                
            case "--scopes": fallthrough
            case "-s":
                scopes = argument
                
            default: break
            }
            key = nil
        }
        
        guard issuer != nil,
              clientId != nil,
              redirectUri != nil else { return nil }
        return try? ClientConfiguration(clientId: clientId!,
                                        issuer: issuer!,
                                        redirectUri: redirectUri!,
                                        scopes: scopes,
                                        shouldSave: false)
    }
    
    static var plistConfiguration: ClientConfiguration? {
        guard let path = Bundle.main.url(forResource: "Okta", withExtension: "plist"),
              let data = try? Data(contentsOf: path),
              let content = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:String],
              let issuer = content["issuer"],
              !issuer.hasPrefix("{"),
              let clientId = content["clientId"],
              !clientId.hasPrefix("{"),
              let scopes = content["scopes"],
              let redirectUri = content["redirectUri"],
              !redirectUri.hasPrefix("{")
        else {
            return nil
        }
        
        return try? ClientConfiguration(clientId: clientId,
                                        issuer: issuer,
                                        redirectUri: redirectUri,
                                        scopes: scopes,
                                        shouldSave: false)
    }
    
    static var userDefaults: ClientConfiguration? {
        let defaults = UserDefaults.standard
        let environment = ProcessInfo.processInfo.environment
        guard let issuer = defaults.string(forKey: issuerKey) ?? ((environment["ISSUER_DOMAIN"] != nil) ? "https://\(environment["ISSUER_DOMAIN"]!)" : nil),
              issuer.count > 0,
              let clientId = defaults.string(forKey: clientIdKey) ?? environment["CLIENT_ID"],
              clientId.count > 0,
              let scopes = defaults.string(forKey: scopesKey) ?? environment["SCOPES"],
              scopes.count > 0,
              let redirectUri = defaults.string(forKey: redirectUriKey) ?? environment["REDIRECT_URI"],
              redirectUri.count > 0
        else {
            return nil
        }
        
        return try? ClientConfiguration(clientId: clientId,
                                        issuer: issuer,
                                        redirectUri: redirectUri,
                                        scopes: scopes,
                                        shouldSave: false)
    }
    
    static var active: ClientConfiguration? {
        launchConfiguration ?? userDefaults ?? plistConfiguration
    }
    
    func save() {
        guard shouldSave else { return }
        
        let defaults = UserDefaults.standard
        defaults.setValue(issuer, forKey: type(of: self).issuerKey)
        defaults.setValue(clientId, forKey: type(of: self).clientIdKey)
        defaults.setValue(redirectUri, forKey: type(of: self).redirectUriKey)
        defaults.setValue(scopes, forKey: type(of: self).scopesKey)
        defaults.synchronize()
        
        NotificationCenter.default.post(name: .configurationChanged, object: self.idxConfiguration)
    }
    
    enum ConfigurationError: Error, LocalizedError {
        case invalidUrl(name: String)
        case missingValue(name: String)
        case missingRecommendedScopes
        case issuerMissingPath
        
        var errorDescription: String? {
            switch self {
            case .invalidUrl(name: let name):
                return "Invalid URL \(name)"
            case .missingValue(name: let name):
                return "Missing required value \(name)"
            case .missingRecommendedScopes:
                return "Missing recommended scopes \"openid\" and \"profile\".\n\nYou may want to include \"offline_access\" to support refresh tokens."
            case .issuerMissingPath:
                return "The issuer URL should include an OAuth2 path, such as \"/oauth2/default\""
            }
        }
    }
}
