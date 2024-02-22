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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaDirectAuth

final class RequestTests: XCTestCase {
    var openIdConfiguration: OpenIdConfiguration!
    
    override func setUpWithError() throws {
        openIdConfiguration = try mock(from: .module,
                                       for: "openid-configuration",
                                       in: "MockResponses")
    }

    func testTokenRequestParameters() throws {
        var request: TokenRequest
        
        // No authentication
        request = .init(openIdConfiguration: openIdConfiguration,
                        clientConfiguration: try .init(domain: "example.com",
                                                       clientId: "theClientId",
                                                       scopes: "openid profile"),
                        currentStatus: nil,
                        factor: DirectAuthenticationFlow.PrimaryFactor.password("password123"))
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "scope": "openid profile",
                        "grant_type": "password",
                        "password": "password123"
                       ])

        // Client Secret authentication
        request = .init(openIdConfiguration: openIdConfiguration,
                        clientConfiguration: try .init(domain: "example.com",
                                                       clientId: "theClientId",
                                                       scopes: "openid profile",
                                                       authentication: .clientSecret("supersecret")),
                        currentStatus: nil,
                        factor: DirectAuthenticationFlow.PrimaryFactor.password("password123"))
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "client_secret": "supersecret",
                        "scope": "openid profile",
                        "grant_type": "password",
                        "password": "password123"
                       ])
    }

    func testOOBAuthenticateRequestParameters() throws {
        var request: OOBAuthenticateRequest
        
        // No authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                            clientConfiguration: try .init(domain: "example.com",
                                                           clientId: "theClientId",
                                                           scopes: "openid profile"),
                            loginHint: "user@example.com",
                            channelHint: .push)
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "channel_hint": "push",
                        "login_hint": "user@example.com"
                       ])

        // Client Secret authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                            clientConfiguration: try .init(domain: "example.com",
                                                           clientId: "theClientId",
                                                           scopes: "openid profile",
                                                           authentication: .clientSecret("supersecret")),
                            loginHint: "user@example.com",
                            channelHint: .push)
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "client_secret": "supersecret",
                        "channel_hint": "push",
                        "login_hint": "user@example.com"
                       ])
    }

    func testChallengeRequestParameters() throws {
        var request: ChallengeRequest
        
        // No authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                            clientConfiguration: try .init(domain: "example.com",
                                                           clientId: "theClientId",
                                                           scopes: "openid profile"),
                            mfaToken: "abcd123",
                            challengeTypesSupported: [.password, .oob])
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "mfa_token": "abcd123",
                        "challenge_types_supported": "password urn:okta:params:oauth:grant-type:oob"
                       ])

        // Client Secret authentication
        request = try .init(openIdConfiguration: openIdConfiguration,
                            clientConfiguration: try .init(domain: "example.com",
                                                           clientId: "theClientId",
                                                           scopes: "openid profile",
                                                           authentication: .clientSecret("supersecret")),
                            mfaToken: "abcd123",
                            challengeTypesSupported: [.password, .oob])
        XCTAssertEqual(request.bodyParameters as? [String: String],
                       [
                        "client_id": "theClientId",
                        "client_secret": "supersecret",
                        "mfa_token": "abcd123",
                        "challenge_types_supported": "password urn:okta:params:oauth:grant-type:oob"
                       ])
    }
}
