//
// Copyright (c) 2026-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

final class SDKVersionRegistrationTests: XCTestCase {
    /// Regression test for #254 — User-Agent header missing in Release builds.
    ///
    /// `SDKVersion.userAgent` is populated as a side effect of evaluating the
    /// lazy `static let` registration in each `Version+*.swift`. That evaluation
    /// must run in every build configuration. This test asserts the contract
    /// after constructing an `OAuth2Client`.
    func testOAuth2ClientInitPopulatesUserAgent() throws {
        let client = OAuth2Client(
            issuerURL: try XCTUnwrap(URL(string: "https://example.okta.com/oauth2/default")),
            clientId: "test-client-id",
            scope: ["openid"]
        )
        _ = client

        XCTAssertFalse(SDKVersion.userAgent.isEmpty,
                       "User-Agent must be populated after OAuth2Client init in any build configuration.")
        XCTAssertTrue(SDKVersion.userAgent.contains("okta-authfoundation-swift/"),
                      "User-Agent must include the AuthFoundation SDK marker; got '\(SDKVersion.userAgent)'.")
    }
}
