//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import Testing
@testable import TestCommon
@testable import AuthFoundation

#if os(Linux) || os(Android)
import FoundationNetworking
#endif

@Suite("OAuth2 Client Configuration")
struct OAuth2ClientConfigurationTests {
    @Test("Initialize using a string literal scope")
    func testStringLiteralInitializer() throws {
        let configuration = OAuth2Client.Configuration(
            issuerURL: URL(string: "https://example.com")!,
            clientId: "abcd123",
            scope: "openid profile",
            authentication: .none)
        #expect(configuration.discoveryURL.absoluteString == "https://example.com/.well-known/openid-configuration")
        #expect(configuration.scope == ["openid", "profile"])
        #expect(configuration.parameters(for: .authorization)?.mapValues(\.stringValue) == [
            "client_id": "abcd123",
            "scope": "openid profile",
        ])
    }
    
    @Test("Initialize using an array literal scope")
    func testArrayLiteralInitializer() throws {
        let configuration = OAuth2Client.Configuration(
            issuerURL: URL(string: "https://example.com/oauth2/default")!,
            clientId: "abcd123",
            scope: ["openid", "email"],
            redirectUri: URL(string: "com.example.app:/"),
            logoutRedirectUri: URL(string: "com.example.app:/logout"),
            authentication: .clientSecret("super_secret"))
        #expect(configuration.discoveryURL.absoluteString == "https://example.com/oauth2/default/.well-known/openid-configuration")
        #expect(configuration.scope == ["openid", "email"])
        #expect(configuration.parameters(for: .authorization)?.mapValues(\.stringValue) == [
            "client_id": "abcd123",
            "client_secret": "super_secret",
            "redirect_uri": "com.example.app:/",
            "scope": "openid email",
        ])
    }
    
    @Test("Initialize using a string value scope")
    func testStringValueInitializer() throws {
        let scopeString = "openid profile"
        let configuration = OAuth2Client.Configuration(
            issuerURL: URL(string: "https://example.com")!,
            clientId: "abcd123",
            scope: scopeString,
            authentication: .none)
        #expect(configuration.scope == ["openid", "profile"])
    }
    
    @Test("Initialize using a array value scope")
    func testArrayValueInitializer() throws {
        let scopeArray = ["openid", "email"]
        let configuration = OAuth2Client.Configuration(
            issuerURL: URL(string: "https://example.com")!,
            clientId: "abcd123",
            scope: scopeArray,
            authentication: .none)
        #expect(configuration.scope == ["openid", "email"])
    }
    
    @Test("Configuration equality comparing clent authentication methods")
    func testConfigurationEquality() throws {
        let clientA = try OAuth2Client.Configuration(domain: "example.com",
                                                     clientId: "abc123",
                                                     scope: "openid profile",
                                                     authentication: .none)
        let clientB = try OAuth2Client.Configuration(domain: "example.com",
                                                     clientId: "abc123",
                                                     scope: "openid profile",
                                                     authentication: .clientSecret("supersecret"))
        #expect(clientA != clientB)
    }
}
