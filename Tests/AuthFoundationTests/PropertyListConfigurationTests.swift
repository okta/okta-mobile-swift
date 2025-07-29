//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Testing
import Foundation

@testable import AuthFoundation
@testable import TestCommon

@Suite("Property List Configuration Tests")
struct PropertyListConfigurationTests {
    typealias PropertyListConfiguration = OAuth2Client.PropertyListConfiguration
    typealias PropertyKey = PropertyListConfiguration.Key

    @Test("Property List Keys validation")
    func propertyListKeys() throws {
        #expect(PropertyKey.issuerURL.rawValue == "issuer_url")
        #expect(PropertyKey.issuerURL.matchingKeys == ["issuer_url", "issuerUrl", "IssuerUrl", "issuer"])

        #expect(PropertyKey.clientId.rawValue == "client_id")
        #expect(PropertyKey.clientId.matchingKeys == ["client_id", "clientId", "ClientId"])
        
        #expect(PropertyKey.scope.rawValue == "scope")
        #expect(PropertyKey.scope.matchingKeys == ["scope", "Scope", "scopes"])

        #expect(PropertyKey.redirectUri.rawValue == "redirect_uri")
        #expect(PropertyKey.redirectUri.matchingKeys == ["redirect_uri", "redirectUri", "RedirectUri"])

        #expect(PropertyKey.logoutRedirectUri.rawValue == "logout_redirect_uri")
        #expect(PropertyKey.logoutRedirectUri.matchingKeys == ["logout_redirect_uri", "logoutRedirectUri", "LogoutRedirectUri"])

        #expect(PropertyKey.clientSecret.rawValue == "client_secret")
        #expect(PropertyKey.clientSecret.matchingKeys == ["client_secret", "clientSecret", "ClientSecret"])
    }
    
    @Test("Legacy Configuration loading")
    func legacyConfiguration() throws {
        let url = try fileUrl(from: Bundle.module, for: "LegacyFormat.plist", in: "ConfigResources")
        let config = try PropertyListConfiguration(plist: url)
        #expect(config.issuerURL.absoluteString == "https://myapp.example.com/oauth2/default")
        #expect(config.clientId == "0oaasdf1234")
        #expect(config.scope == ["openid", "profile", "offline_access"])
        #expect(config.redirectUri?.absoluteString == "com.example:/callback")
        #expect(config.logoutRedirectUri?.absoluteString == "com.example:/")
        #expect(config.additionalParameters?.mapValues { param in param.stringValue } == [
            "custom": "value",
        ])
    }

    @Test("Snake Case Keys loading")
    func snakeCaseKeys() throws {
        let url = try fileUrl(from: .module, for: "SnakeCaseKeys.plist", in: "ConfigResources")
        let config = try PropertyListConfiguration(plist: url)
        #expect(config.issuerURL.absoluteString == "https://myapp.example.com/oauth2/default")
        #expect(config.clientId == "0oaasdf1234")
        #expect(config.scope == ["openid", "profile", "offline_access"])
        #expect(config.redirectUri?.absoluteString == "com.example:/callback")
        #expect(config.logoutRedirectUri?.absoluteString == "com.example:/")
        #expect(config.additionalParameters?.mapValues { param in param.stringValue } == [
            "custom": "value",
        ])
    }

    @Test("Dictionary Values configuration")
    func dictionaryValues() throws {
        let config = try PropertyListConfiguration([
            "issuer_url": "https://myapp.example.com/oauth2/default",
            "clientId": "0oaasdf1234",
            "scopes": "openid profile offline_access",
            "redirect_uri": "com.example:/callback",
            "logout_redirect_uri": "com.example:/",
            "custom": "value",
        ])
        #expect(config.issuerURL.absoluteString == "https://myapp.example.com/oauth2/default")
        #expect(config.clientId == "0oaasdf1234")
        #expect(config.scope == ["openid", "profile", "offline_access"])
        #expect(config.redirectUri?.absoluteString == "com.example:/callback")
        #expect(config.logoutRedirectUri?.absoluteString == "com.example:/")
        #expect(config.additionalParameters?.mapValues(\.stringValue) == [
            "custom": "value",
        ])
    }
    
    @Test("Command Line Arguments configuration")
    func commandLineArguments() throws {
        let config = try PropertyListConfiguration(commandLine: [
            "--issuerUrl=https://myapp.example.com/oauth2/default",
            "--client-id=0oaasdf1234",
            "--redirect_uri",
            "com.example:/callback",
            "--LogoutRedirectUri",
            "com.example:/",
            "--scopes",
            "openid profile offline_access",
            "--custom=value"
        ])
        #expect(config.issuerURL.absoluteString == "https://myapp.example.com/oauth2/default")
        #expect(config.clientId == "0oaasdf1234")
        #expect(config.scope == ["openid", "profile", "offline_access"])
        #expect(config.redirectUri?.absoluteString == "com.example:/callback")
        #expect(config.logoutRedirectUri?.absoluteString == "com.example:/")
        #expect(config.additionalParameters?.mapValues(\.stringValue) == [
            "custom": "value",
        ])
    }
}
