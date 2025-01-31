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

import XCTest

@testable import AuthFoundation
@testable import TestCommon

final class PropertyListConfigurationTests: XCTestCase {
    typealias PropertyListConfiguration = OAuth2Client.PropertyListConfiguration
    
    func testLegacyConfiguration() throws {
        let url = try fileUrl(from: .module, for: "LegacyFormat.plist", in: "ConfigResources")
        let config = try PropertyListConfiguration(plist: url)
        XCTAssertEqual(config.issuerURL.absoluteString, "https://myapp.example.com/oauth2/default")
        XCTAssertEqual(config.clientId, "0oaasdf1234")
        XCTAssertEqual(config.scope, "openid profile offline_access")
        XCTAssertEqual(config.redirectUri?.absoluteString, "com.example:/callback")
        XCTAssertEqual(config.logoutRedirectUri?.absoluteString, "com.example:/")
        XCTAssertEqual(config.additionalParameters?.mapValues(\.stringValue), [
            "custom": "value",
        ])
    }

    func testSnakeCaseKeys() throws {
        let url = try fileUrl(from: .module, for: "SnakeCaseKeys.plist", in: "ConfigResources")
        let config = try PropertyListConfiguration(plist: url)
        XCTAssertEqual(config.issuerURL.absoluteString, "https://myapp.example.com/oauth2/default")
        XCTAssertEqual(config.clientId, "0oaasdf1234")
        XCTAssertEqual(config.scope, "openid profile offline_access")
        XCTAssertEqual(config.redirectUri?.absoluteString, "com.example:/callback")
        XCTAssertEqual(config.logoutRedirectUri?.absoluteString, "com.example:/")
        XCTAssertEqual(config.additionalParameters?.mapValues(\.stringValue), [
            "custom": "value",
        ])
    }
}
