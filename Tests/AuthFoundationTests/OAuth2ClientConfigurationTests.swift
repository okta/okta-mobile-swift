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

import XCTest
@testable import TestCommon
@testable import AuthFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class OAuth2ClientConfigurationTests: XCTestCase {
    func testInitializers() throws {
        var configuration: OAuth2Client.Configuration!
        
        // Tewst with a string literal scope
        configuration = .init(issuerURL: URL(string: "https://example.com")!,
                              clientId: "abcd123",
                              scope: "openid profile",
                              authentication: .none)
        XCTAssertEqual(configuration.discoveryURL.absoluteString, "https://example.com/.well-known/openid-configuration")
        XCTAssertEqual(configuration.scope, ["openid", "profile"])
        XCTAssertEqual(configuration.parameters(for: .authorization)?.mapValues(\.stringValue), [
            "client_id": "abcd123",
            "scope": "openid profile",
        ])
        
        // Test with an array literal scope
        configuration = .init(issuerURL: URL(string: "https://example.com/oauth2/default")!,
                              clientId: "abcd123",
                              scope: ["openid", "email"],
                              redirectUri: URL(string: "com.example.app:/"),
                              logoutRedirectUri: URL(string: "com.example.app:/logout"),
                              authentication: .clientSecret("super_secret"))
        XCTAssertEqual(configuration.discoveryURL.absoluteString, "https://example.com/oauth2/default/.well-known/openid-configuration")
        XCTAssertEqual(configuration.scope, ["openid", "email"])
        XCTAssertEqual(configuration.parameters(for: .authorization)?.mapValues(\.stringValue), [
            "client_id": "abcd123",
            "client_secret": "super_secret",
            "redirect_uri": "com.example.app:/",
            "scope": "openid email",
        ])

        // Test with a string value scope
        let scopeString = "openid profile"
        configuration = .init(issuerURL: URL(string: "https://example.com")!,
                              clientId: "abcd123",
                              scope: scopeString,
                              authentication: .none)
        XCTAssertEqual(configuration.scope, ["openid", "profile"])

        // Test with an array value scope
        let scopeArray = ["openid", "email"]
        configuration = .init(issuerURL: URL(string: "https://example.com")!,
                              clientId: "abcd123",
                              scope: scopeArray,
                              authentication: .none)
        XCTAssertEqual(configuration.scope, ["openid", "email"])
    }
    
    func testConfiguration() throws {
        XCTAssertNotEqual(try OAuth2Client.Configuration(domain: "example.com",
                                                         clientId: "abc123",
                                                         scope: "openid profile",
                                                         authentication: .none),
                          try OAuth2Client.Configuration(domain: "example.com",
                                                         clientId: "abc123",
                                                         scope: "openid profile",
                                                         authentication: .clientSecret("supersecret")))
    }
}
