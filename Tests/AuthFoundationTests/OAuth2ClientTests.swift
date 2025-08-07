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

import Foundation
import Testing
@testable import TestCommon
@testable import AuthFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Suite("OAuth2 Client", .disabled("Debugging test deadlocks within CI"))
struct OAuth2ClientTests {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")
    let openIdConfiguration = try! OpenIdConfiguration.jsonDecoder.decode(
        OpenIdConfiguration.self,
        from: try! data(from: Bundle.module,
                       for: "openid-configuration",
                       in: "MockResponses"))

    let token: Token

    init() {
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
    }

    @Test("Simple OAuth2 initialization with a domain")
    func testSimpleDomainInitializer() throws {
        let client = try OAuth2Client(.init(domain: "example.com",
                                            clientId: "abc123",
                                            scope: "openid profile"))
        #expect(client.configuration == .init(issuerURL: URL(string: "https://example.com")!,
                                              clientId: "abc123",
                                              scope: "openid profile",
                                              authentication: .none))
        
        // Ensure the default session is ephemeral
        let urlSession = try #require(client.session as? URLSession)
        #expect(urlSession.configuration.urlCache?.diskCapacity == 0)
    }

    @Test("Simple OAuth2 initialization with an issuer URL")
    func testSimpleIssuerInitializer() throws {
        let client = OAuth2Client(issuerURL: URL(string: "https://example.com")!,
                                  clientId: "abc123",
                                  scope: "openid profile")
        #expect(client.configuration == .init(issuerURL: URL(string: "https://example.com")!,
                                              clientId: "abc123",
                                              scope: "openid profile",
                                              authentication: .none))
    }

    @Test("OAuth2 initialization with a client secret")
    func testSimpleIssuerClientSecretInitializer() throws {
        let client = try OAuth2Client(.init(domain: "example.com",
                                            clientId: "abc123",
                                            scope: "openid profile",
                                            authentication: .clientSecret("supersecret")))
        #expect(client.configuration == .init(issuerURL: URL(string: "https://example.com")!,
                                              clientId: "abc123",
                                              scope: "openid profile",
                                              authentication: .clientSecret("supersecret")))
    }
    
    @Test("Client authentication methods and parameter generation")
    func testClientAuthentication() throws {
        typealias ClientAuth = OAuth2Client.ClientAuthentication
        #expect(ClientAuth.none != .clientSecret("supersecret"))
        #expect(ClientAuth.none == .none)
        
        #expect(ClientAuth.clientSecret("supersecret1") != .clientSecret("supersecret2"))
        #expect(ClientAuth.clientSecret("supersecret") == .clientSecret("supersecret"))

        for category in OAuth2APIRequestCategory.allCases.omitting(.configuration) {
            #expect(ClientAuth.none.parameters(for: category) == nil)
            #expect(ClientAuth.clientSecret("supersecret").parameters(for: category)?.stringComponents ==
                    ["client_secret": "supersecret"])
        }
        
        #expect(ClientAuth.none.parameters(for: .configuration) == nil)
        #expect(ClientAuth.clientSecret("supersecret").parameters(for: .configuration) == nil)
    }

    @Test("Fetch OpenIDConfiguration concurrently with completion blocks")
    func testOpenIDConfiguration() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        let results = try await repeatedlyConfirmClosure("Perform openIdConfiguration fetches") { _, confirm in
            client.openIdConfiguration {
                confirm($0)
            }
        }

        #expect(results.count == 4)
        let config = try #require(results.first)
        #expect(config.authorizationEndpoint.absoluteString == "https://example.com/oauth2/v1/authorize")
    }
    
    @Test("Fetch OpenIDConfiguration concurrently with async/await")
    func testOpenIDConfigurationAsync() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: Bundle.module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let config = try await client.openIdConfiguration()
        #expect(config.authorizationEndpoint.absoluteString == "https://example.com/oauth2/v1/authorize")
    }
    
    @Test("Fetch the JWKS endpoint concurrently with completion blocks")
    func testJWKS() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=clientid",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        
        let results = try await repeatedlyConfirmClosure("Perform jwks fetches") { _, confirm in
            client.jwks {
                confirm($0)
            }
        }

        #expect(results.count == 4)
        for jwks in results {
            let jwk = try #require(jwks.first)
            #expect(jwk.id == "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA")
        }
    }

    @Test("Fetch userinfo with completion blocks", .credentialCoordinator)
    func testUserInfo() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)
        
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
        
        try Credential.store(token)
        
        let userInfo = try await confirmClosure("Perform jwks fetches") { confirm in
            client.userInfo(token: token) {
                confirm($0)
            }
        }
        
        #expect(userInfo.subject == "00uid4BxXw6I6TV4m0g3")
    }

    @Test("Token introspection request creation and parameters", .credentialCoordinator)
    func testIntrospectTokenRequest() async throws {
        let request = try Token.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                  clientConfiguration: configuration,
                                                  token: token,
                                                  type: .accessToken)
        #expect(request.authorization == nil)
        #expect((request.bodyParameters?["client_id"] as? String) == "clientid")
        #expect(request.bodyParameters?["token"] as? String == "abcd123")
        #expect(request.bodyParameters?["token_type_hint"]?.stringValue == "access_token")
        #expect(request.bodyParameters?["client_secret"] == nil)
    }
    
    @Test("Token introspection request with client secret authentication")
    func testIntrospectTokenRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(issuerURL: configuration.baseURL,
                                                             clientId: configuration.clientId,
                                                             scope: configuration.scope,
                                                             authentication: .clientSecret("supersecret"))
        let request = try Token.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                  clientConfiguration: clientConfiguration,
                                                  token: token,
                                                  type: .accessToken)
        #expect(request.authorization == nil)
        #expect((request.bodyParameters?["client_id"] as? String) == "clientid")
        #expect((request.bodyParameters?["client_secret"] as? String) == "supersecret")
        #expect(request.bodyParameters?["token"] as? String == "abcd123")
        #expect(request.bodyParameters?["token_type_hint"]?.stringValue == "access_token")
    }
    
    @Test("Token introspection of an active token", .credentialCoordinator)
    func testIntrospectActiveAccessToken() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)
        
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

        let tokenInfo = try await confirmClosure("Introspect access token") { confirm in
            client.introspect(token: token, type: .accessToken) { confirm($0) }
        }
        
        #expect(tokenInfo.subject == "john.doe@example.com")
        #expect(tokenInfo.active == true)
    }
    
    @Test("Token introspection of an inactive access token", .credentialCoordinator)
    func testIntrospectInactiveAccessToken() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)
        
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

        let tokenInfo = try await confirmClosure("Introspect access token") { confirm in
            client.introspect(token: token, type: .accessToken) { confirm($0) }
        }

        #expect(tokenInfo.active == false)
    }
    
    @Test("Token introspection of an active refresh token", .credentialCoordinator)
    func testIntrospectActiveRefreshToken() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

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

        let tokenInfo = try await confirmClosure("Introspect refresh token") { confirm in
            client.introspect(token: token, type: .refreshToken) { confirm($0) }
        }

        #expect(tokenInfo.subject == "john.doe@example.com")
        #expect(tokenInfo.active == true)
    }
    
    @Test("Token introspection of an active ID token", .credentialCoordinator)
    func testIntrospectActiveIdToken() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

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

        let tokenInfo = try await confirmClosure("Introspect ID token") { confirm in
            client.introspect(token: token, type: .idToken) { confirm($0) }
        }
        
        #expect(tokenInfo.subject == "john.doe@example.com")
        #expect(tokenInfo.active == true)
    }
    
    @Test("Token introspection of an active device secret", .credentialCoordinator)
    func testIntrospectActiveDeviceSecret() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

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

        let tokenInfo = try await confirmClosure("Introspect device secret") { confirm in
            client.introspect(token: token, type: .deviceSecret) { confirm($0) }
        }

        #expect(tokenInfo.subject == "john.doe@example.com")
        #expect(tokenInfo.active == true)
    }
    
    @Test("Token introspection failure", .credentialCoordinator)
    func testIntrospectFailed() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        let token = try! Token(id: "TokenId",
                               issuedAt: Date(),
                               tokenType: "Bearer",
                               expiresIn: 300,
                               accessToken: "abcd123",
                               scope: "openid",
                               refreshToken: nil,
                               idToken: nil,
                               deviceSecret: nil,
                               context: Token.Context(configuration: configuration,
                                                      clientSettings: nil))
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/introspect", data: nil, statusCode: 401)

        let error = await #expect(throws: (any Error).self) {
            try await confirmClosure("Introspect refresh token") { confirm in
                client.introspect(token: token, type: .refreshToken) { confirm($0) }
            }
        }

        let expectedUrlRequest = URLRequest(url: URL(string: "https://example.com/oauth2/v1/introspect")!)
        #expect(error?.localizedDescription ==
                OAuth2Error.network(error: APIClientError.missingResponse(request: expectedUrlRequest)).localizedDescription)
    }
 
    @Test("Revoke access token", .credentialCoordinator)
    func testRevoke() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        try await confirmClosure("Introspect device secret") { confirm in
            client.revoke(token, type: .accessToken) { confirm($0) }
        }
    }
    
    @Test("Revoke request parameters with client authentication")
    func testRevokeRequestClientAuthentication() throws {
        var config = configuration
        config.authentication = .clientSecret("supersecret")
        let request = try Token.RevokeRequest(openIdConfiguration: openIdConfiguration,
                                              clientConfiguration: config,
                                              token: "the-token",
                                              hint: .deviceSecret,
                                              configuration: [:])
        let parameters = try #require(request.bodyParameters?.stringComponents)
        #expect(parameters["token"] == "the-token")
        #expect(parameters["token_type_hint"] == "device_secret")
        #expect(parameters["client_secret"] == "supersecret")
    }

    @Test("Refresh token concurrently", .credentialCoordinator)
    func testRefresh() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let results = try await repeatedlyConfirmClosure("Perform jwks fetches") { _, confirm in
            client.refresh(token) {
                confirm($0)
            }
        }

        #expect(results.count == 4)
    }

    @Test("Validate refresh request parameters with client authentication", .credentialCoordinator)
    func testRefreshRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(issuerURL: configuration.baseURL,
                                                             clientId: configuration.clientId,
                                                             scope: configuration.scope,
                                                             authentication: .clientSecret("supersecret"))
        let request = Token.RefreshRequest(openIdConfiguration: openIdConfiguration,
                                           clientConfiguration: clientConfiguration,
                                           refreshToken: "the-token",
                                           scope: nil,
                                           id: "token-id")
        let parameters = try #require(request.bodyParameters as? [String: String])
        #expect(parameters["refresh_token"] == "the-token")
        #expect(parameters["grant_type"] == "refresh_token")
        #expect(parameters["client_secret"] == "supersecret")
    }

    @Test("Refresh token async", .credentialCoordinator)
    func testRefreshAsync() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        _ = try await client.refresh(token)
    }

    @Test("Refresh revoke async", .credentialCoordinator)
    func testRevokeAsync() async throws {
        let urlSession = URLSessionMock()
        let client = OAuth2Client(configuration, session: urlSession)

        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        _ = try await client.revoke(token, type: .accessToken)
    }
}
