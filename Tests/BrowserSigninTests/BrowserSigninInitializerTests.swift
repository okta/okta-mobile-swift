//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OAuth2Auth
@testable import BrowserSignin

class BrowserSigninInitializerTests: XCTestCase {
    private let issuer = URL(string: "https://example.com")!
    private let redirectUri = URL(string: "com.example:/callback")!
    private let logoutRedirectUri = URL(string: "com.example:/logout")!

    override func setUp() async throws {
        await MainActor.run {
            BrowserSignin.providerFactory = BrowserSigninProviderFactoryMock.self
        }
    }

    override func tearDown() async throws {
        await BrowserSignin.resetToDefault()
    }

    func testInitializer() async throws {
        let auth = await BrowserSignin(
            issuerURL: issuer,
            clientId: "client_id",
            scope: "openid profile",
            redirectUri: redirectUri,
            logoutRedirectUri: logoutRedirectUri,
            additionalParameters: ["foo": "bar"])

        let signInFlowClient = auth.signInFlow.client
        let signOutFlowClient = auth.signOutFlow?.client
        XCTAssertEqual(signInFlowClient.configuration.clientId, "client_id")
        XCTAssertEqual(signInFlowClient.configuration.scope, ["openid", "profile"])
        XCTAssertTrue(signInFlowClient === signOutFlowClient)
        XCTAssertEqual(auth.signInFlow.additionalParameters?.stringComponents, ["foo": "bar"])
        XCTAssertEqual(auth.signOutFlow?.additionalParameters?.stringComponents, ["foo": "bar"])
    }

    @MainActor
    func testOptions() async throws {
        let auth = BrowserSignin(
            issuerURL: issuer,
            clientId: "client_id",
            scope: "openid profile",
            redirectUri: redirectUri)

        XCTAssertEqual(auth.options, [])
        
        auth.ephemeralSession = true
        XCTAssertEqual(auth.options, [.ephemeralSession])
        XCTAssertTrue(auth.ephemeralSession)

        auth.ephemeralSession = false
        XCTAssertEqual(auth.options, [])
        XCTAssertFalse(auth.ephemeralSession)

        auth.options = [.ephemeralSession]
        XCTAssertEqual(auth.options, [.ephemeralSession])
        XCTAssertTrue(auth.ephemeralSession)
    }
}
