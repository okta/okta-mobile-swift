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
import CommonSupport
@testable import TestCommon
@testable import AuthFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")
    var token: Token!

    override func setUp() async throws {
        await CredentialActor.run {
            Credential.tokenStorage = MockTokenStorage()
            Credential.credentialDataSource = MockCredentialDataSource()
        }

        urlSession = URLSessionMock()
        client = OAuth2Client(configuration, session: urlSession)
        
        token = try! Token(id: "TokenId",
                           issuedAt: Date(),
                           tokenType: "Bearer",
                           expiresIn: 300,
                           accessToken: "abcd123",
                           scope: "openid",
                           refreshToken: "refresh",
                           idToken: nil,
                           deviceSecret: nil,
                           context: Token.Context(configuration: self.configuration,
                                                  clientSettings: [ "client_id": "clientid", "refresh_token": "refresh" ]))
        try Credential.store(token)
        
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))

        urlSession.requestDelay = 0.1
    }

    override func tearDown() async throws {
        await CredentialActor.run {
            TaskData.coordinator.resetToDefault()
        }
        
        urlSession = nil
        client = nil
    }
    
    func testInitializers() throws {
        var client: OAuth2Client!
        
        client = try OAuth2Client(.init(domain: "example.com",
                                        clientId: "abc123",
                                        scope: "openid profile"))
        XCTAssertEqual(client.configuration, .init(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scope: "openid profile",
                                                   authentication: .none))
        
        // Ensure the default session is ephemeral
        let urlSession = try XCTUnwrap(client.session as? URLSession)
        XCTAssertEqual(urlSession.configuration.urlCache?.diskCapacity, 0)

        client = OAuth2Client(issuerURL: URL(string: "https://example.com")!,
                              clientId: "abc123",
                              scope: "openid profile")
        XCTAssertEqual(client.configuration, .init(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scope: "openid profile",
                                                   authentication: .none))
        
        client = try OAuth2Client(.init(domain: "example.com",
                                        clientId: "abc123",
                                        scope: "openid profile",
                                        authentication: .clientSecret("supersecret")))
        XCTAssertEqual(client.configuration, .init(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scope: "openid profile",
                                                   authentication: .clientSecret("supersecret")))
    }
    
    func testClientAuthentication() throws {
        XCTAssertNotEqual(OAuth2Client.ClientAuthentication.none,
                          .clientSecret("supersecret"))
        XCTAssertEqual(OAuth2Client.ClientAuthentication.none, .none)
        
        XCTAssertNotEqual(OAuth2Client.ClientAuthentication.clientSecret("supersecret1"),
                          .clientSecret("supersecret2"))
        XCTAssertEqual(OAuth2Client.ClientAuthentication.clientSecret("supersecret"),
                       .clientSecret("supersecret"))

        for category in OAuth2APIRequestCategory.allCases.omitting(.configuration) {
            XCTAssertNil(OAuth2Client.ClientAuthentication.none.parameters(for: category))
            XCTAssertEqual(OAuth2Client.ClientAuthentication.clientSecret("supersecret").parameters(for: category)?.stringComponents,
                           ["client_secret": "supersecret"])
        }
        
        XCTAssertNil(OAuth2Client.ClientAuthentication.none.parameters(for: .configuration))
        XCTAssertNil(OAuth2Client.ClientAuthentication.clientSecret("supersecret").parameters(for: .configuration))

    }

    func testOpenIDConfiguration() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        nonisolated(unsafe) var configResults = [OpenIdConfiguration]()
        var expectations = [XCTestExpectation]()
        let lock = Lock()

        for index in 1...4 {
            let expect = expectation(description: "network request \(index)")
            client.openIdConfiguration { result in
                switch result {
                case .success(let configuration):
                    lock.withLock {
                        configResults.append(configuration)
                    }
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
            expectations.append(expect)
        }
        
        wait(for: expectations, timeout: 2)

        XCTAssertEqual(configResults.count, 4)
        let config = try XCTUnwrap(configResults.first)
        XCTAssertEqual(config.authorizationEndpoint.absoluteString,
                       "https://example.com/oauth2/v1/authorize")
    }
    
    func testOpenIDConfigurationAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let client = try XCTUnwrap(self.client)
        try await perform {
            let config = try await client.openIdConfiguration()
            XCTAssertEqual(config.authorizationEndpoint.absoluteString,
                           "https://example.com/oauth2/v1/authorize")
        }
    }
    
    func testJWKS() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=clientid",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        
        nonisolated(unsafe) var jwksResults = [JWKS]()
        var expectations = [XCTestExpectation]()
        let lock = Lock()

        for _ in 1...4 {
            let expect = expectation(description: "network request")
            client.jwks { result in
                switch result {
                case .success(let jwks):
                    lock.withLock {
                        jwksResults.append(jwks)
                    }
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
            expectations.append(expect)
        }
        
        await fulfillment(of: expectations, timeout: 1.5)

        XCTAssertEqual(jwksResults.count, 4)
        let jwks = try XCTUnwrap(jwksResults.first)
        XCTAssertEqual(jwks.first?.id,
                       "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA")
    }

    func testUserInfo() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/userinfo",
                          data: data(for: """
                            {
                              "sub": "00uid4BxXw6I6TV4m0g3",
                              "name" :"John Doe",
                              "nickname":"Jimmy",
                              "given_name":"John",
                              "middle_name":"James",
                              "family_name":"Doe",
                              "profile":"https://example.com/john.doe",
                              "zoneinfo":"America/Los_Angeles",
                              "locale":"en-US",
                              "updated_at":1311280970,
                              "email":"john.doe@example.com",
                              "email_verified":true,
                              "address" : { "street_address":"123 Hollywood Blvd.", "locality":"Los Angeles", "region":"CA", "postal_code":"90210", "country":"US" },
                              "phone_number":"+1 (425) 555-1212"
                            }
                          """),
                          contentType: "application/json")

        nonisolated(unsafe) var userInfo: UserInfo?
        let expect = expectation(description: "network request")
        client.userInfo(token: token) { result in
            switch result {
            case .success(let response):
                userInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        await fulfillment(of: [expect], timeout: .standard)

        XCTAssertEqual(userInfo?.subject, "00uid4BxXw6I6TV4m0g3")
    }

    func testIntrospectTokenRequest() throws {
        let request = try Token.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                  clientConfiguration: client.configuration,
                                                  token: token,
                                                  type: .accessToken)
        XCTAssertNil(request.authorization)
        XCTAssertEqual((request.bodyParameters?["client_id"] as? String), "clientid")
        XCTAssertEqual(request.bodyParameters?["token"] as? String, "abcd123")
        XCTAssertEqual(request.bodyParameters?["token_type_hint"]?.stringValue, "access_token")
        XCTAssertNil(request.bodyParameters?["client_secret"])
    }
    
    func testIntrospectTokenRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(issuerURL: client.configuration.baseURL,
                                                             clientId: client.configuration.clientId,
                                                             scope: client.configuration.scope,
                                                             authentication: .clientSecret("supersecret"))
        let request = try Token.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                  clientConfiguration: clientConfiguration,
                                                  token: token,
                                                  type: .accessToken)
        XCTAssertNil(request.authorization)
        XCTAssertEqual((request.bodyParameters?["client_id"] as? String), "clientid")
        XCTAssertEqual((request.bodyParameters?["client_secret"] as? String), "supersecret")
        XCTAssertEqual(request.bodyParameters?["token"] as? String, "abcd123")
        XCTAssertEqual(request.bodyParameters?["token_type_hint"]?.stringValue, "access_token")
    }
    
    func testIntrospectActiveAccessToken() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect",
                          data: data(for: """
                            {
                              "active" : true,
                              "token_type" : "Bearer",
                              "scope" : "openid profile email",
                              "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
                              "username" : "john.doe@example.com",
                              "exp" : 1451606400,
                              "sub" : "john.doe@example.com",
                              "device_id" : "q4SZgrA9sOeHkfst5uaa"
                            }
                          """),
                          contentType: "application/json")

        nonisolated(unsafe) var tokenInfo: TokenInfo?
        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .accessToken) { result in
            switch result {
            case .success(let response):
                tokenInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectInactiveAccessToken() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect",
                          data: data(for: """
                            {
                              "active" : false
                            }
                          """),
                          contentType: "application/json")
        nonisolated(unsafe) var tokenInfo: TokenInfo?
        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .accessToken) { result in
            switch result {
            case .success(let response):
                tokenInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
        
        XCTAssertEqual(tokenInfo?.active, false)
    }
    
    func testIntrospectActiveRefreshToken() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect",
                          data: data(for: """
                            {
                              "active" : true,
                              "token_type" : "Bearer",
                              "scope" : "openid profile email",
                              "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
                              "username" : "john.doe@example.com",
                              "exp" : 1451606400,
                              "sub" : "john.doe@example.com",
                              "device_id" : "q4SZgrA9sOeHkfst5uaa"
                            }
                          """),
                          contentType: "application/json")

        nonisolated(unsafe) var tokenInfo: TokenInfo?
        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .refreshToken) { result in
            switch result {
            case .success(let response):
                tokenInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectActiveIdToken() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect",
                          data: data(for: """
                            {
                              "active" : true,
                              "token_type" : "Bearer",
                              "scope" : "openid profile email",
                              "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
                              "username" : "john.doe@example.com",
                              "exp" : 1451606400,
                              "sub" : "john.doe@example.com",
                              "device_id" : "q4SZgrA9sOeHkfst5uaa"
                            }
                          """),
                          contentType: "application/json")

        nonisolated(unsafe) var tokenInfo: TokenInfo?
        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .idToken) { result in
            switch result {
            case .success(let response):
                tokenInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectActiveDeviceSecret() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect",
                          data: data(for: """
                            {
                              "active" : true,
                              "token_type" : "Bearer",
                              "scope" : "openid profile email",
                              "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
                              "username" : "john.doe@example.com",
                              "exp" : 1451606400,
                              "sub" : "john.doe@example.com",
                              "device_id" : "q4SZgrA9sOeHkfst5uaa"
                            }
                          """),
                          contentType: "application/json")

        nonisolated(unsafe) var tokenInfo: TokenInfo?
        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .deviceSecret) { result in
            switch result {
            case .success(let response):
                tokenInfo = response
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectFailed() async throws {
        let token = try! Token(id: "TokenId",
                               issuedAt: Date(),
                               tokenType: "Bearer",
                               expiresIn: 300,
                               accessToken: "abcd123",
                               scope: "openid",
                               refreshToken: nil,
                               idToken: nil,
                               deviceSecret: nil,
                               context: Token.Context(configuration: self.configuration,
                                                      clientSettings: nil))
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect", data: nil, statusCode: 401)

        let expect = expectation(description: "network request")
        client.introspect(token: token, type: .refreshToken) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertNotNil(error)

                let expectedUrlRequest = URLRequest(url: URL(string: "https://example.com/oauth2/v1/introspect")!)
                XCTAssertEqual(error.localizedDescription,
                               OAuth2Error.network(error: APIClientError.missingResponse(request: expectedUrlRequest)).localizedDescription)
            }
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: .standard)
    }
 
    func testRevoke() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        let expect = expectation(description: "network request")
        client.revoke(token, type: .accessToken) { result in
            switch result {
            case .success(): break
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        await fulfillment(of: [expect], timeout: .standard)
    }
    
    func testRevokeRequestClientAuthentication() throws {
        var config = configuration
        config.authentication = .clientSecret("supersecret")
        let request = try Token.RevokeRequest(openIdConfiguration: openIdConfiguration,
                                              clientConfiguration: config,
                                              token: "the-token",
                                              hint: .deviceSecret,
                                              configuration: [:])
        let parameters = try XCTUnwrap(request.bodyParameters?.stringComponents)
        XCTAssertEqual(parameters["token"], "the-token")
        XCTAssertEqual(parameters["token_type_hint"], "device_secret")
        XCTAssertEqual(parameters["client_secret"], "supersecret")
    }

    func testRefresh() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        nonisolated(unsafe) var newTokens = [Token]()
        var expectations = [XCTestExpectation]()
        let lock = Lock()

        for _ in 1...4 {
            let expect = expectation(description: "refresh")
            client.refresh(token) { result in
                switch result {
                case .success(let newToken):
                    lock.withLock {
                        newTokens.append(newToken)
                    }
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
            expectations.append(expect)
        }

        await fulfillment(of: expectations, timeout: 1.5)

        XCTAssertEqual(newTokens.count, 4)
    }

    func testRefreshRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(issuerURL: client.configuration.baseURL,
                                                             clientId: client.configuration.clientId,
                                                             scope: client.configuration.scope,
                                                             authentication: .clientSecret("supersecret"))
        let request = Token.RefreshRequest(openIdConfiguration: openIdConfiguration,
                                           clientConfiguration: clientConfiguration,
                                           refreshToken: "the-token",
                                           scope: nil,
                                           id: "token-id")
        let parameters = try XCTUnwrap(request.bodyParameters as? [String: String])
        XCTAssertEqual(parameters["refresh_token"], "the-token")
        XCTAssertEqual(parameters["grant_type"], "refresh_token")
        XCTAssertEqual(parameters["client_secret"], "supersecret")
    }

    func testRefreshAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let token = try await client.refresh(token)
        XCTAssertNotNil(token)
    }

    func testRevokeAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        try await client.revoke(token, type: .accessToken)
    }
}
