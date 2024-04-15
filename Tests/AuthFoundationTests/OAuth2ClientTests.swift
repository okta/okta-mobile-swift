import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    let configuration = OAuth2Client.Configuration(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scopes: "openid")
    var token: Token!

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        client = OAuth2Client(configuration, session: urlSession)
        
        token = Token(id: "TokenId",
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
        
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))

        urlSession.requestDelay = 0.1
    }
    
    override func tearDownWithError() throws {
        urlSession = nil
        client = nil
    }
    
    func testInitializers() throws {
        var client: OAuth2Client!
        
        client = try OAuth2Client(domain: "example.com",
                                  clientId: "abc123",
                                  scopes: "openid profile")
        XCTAssertEqual(client.configuration, .init(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scopes: "openid profile",
                                                   authentication: .none))
        
        // Ensure the default session is ephemeral
        let urlSession = try XCTUnwrap(client.session as? URLSession)
        XCTAssertEqual(urlSession.configuration.urlCache?.diskCapacity, 0)

        client = OAuth2Client(baseURL: URL(string: "https://example.com")!,
                                  clientId: "abc123",
                                  scopes: "openid profile")
        XCTAssertEqual(client.configuration, .init(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scopes: "openid profile",
                                                   authentication: .none))

        client = try OAuth2Client(domain: "example.com",
                                  clientId: "abc123",
                                  scopes: "openid profile",
                                  authentication: .clientSecret("supersecret"))
        XCTAssertEqual(client.configuration, .init(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "abc123",
                                                   scopes: "openid profile",
                                                   authentication: .clientSecret("supersecret")))
    }
    
    func testConfiguration() throws {
        XCTAssertNotEqual(try OAuth2Client.Configuration(domain: "example.com",
                                                         clientId: "abc123",
                                                         scopes: "openid profile",
                                                         authentication: .none),
                          try OAuth2Client.Configuration(domain: "example.com",
                                                                           clientId: "abc123",
                                                                           scopes: "openid profile",
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
        
        XCTAssertNil(OAuth2Client.ClientAuthentication.none.additionalParameters)
        XCTAssertEqual(OAuth2Client.ClientAuthentication.clientSecret("supersecret").additionalParameters,
                       ["client_secret": "supersecret"])
    }

    func testOpenIDConfiguration() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        var configResults = [OpenIdConfiguration]()

        for _ in 1...4 {
            let expect = expectation(description: "network request")
            client.openIdConfiguration { result in
                switch result {
                case .success(let configuration):
                    configResults.append(configuration)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(configResults.count, 4)
        let config = try XCTUnwrap(configResults.first)
        XCTAssertEqual(config.authorizationEndpoint.absoluteString,
                       "https://example.com/oauth2/v1/authorize")
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testOpenIDConfigurationAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let client = try XCTUnwrap(self.client)
        try perform {
            let config = try await client.openIdConfiguration()
            XCTAssertEqual(config.authorizationEndpoint.absoluteString,
                           "https://example.com/oauth2/v1/authorize")
        }
    }
    #endif
    
    func testJWKS() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=clientid",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        
        var jwksResults = [JWKS]()

        for _ in 1...4 {
            let expect = expectation(description: "network request")
            client.jwks { result in
                switch result {
                case .success(let jwks):
                    jwksResults.append(jwks)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(jwksResults.count, 4)
        let jwks = try XCTUnwrap(jwksResults.first)
        XCTAssertEqual(jwks.first?.id,
                       "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA")
    }

    func testUserInfo() throws {
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

        var userInfo: UserInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
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
        XCTAssertEqual(request.bodyParameters?["token_type_hint"] as? String, "access_token")
        XCTAssertNil(request.bodyParameters?["client_secret"])
    }
    
    func testIntrospectTokenRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(baseURL: client.configuration.baseURL,
                                                             clientId: client.configuration.clientId,
                                                             scopes: client.configuration.scopes,
                                                             authentication: .clientSecret("supersecret"))
        let request = try Token.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                  clientConfiguration: clientConfiguration,
                                                  token: token,
                                                  type: .accessToken)
        XCTAssertNil(request.authorization)
        XCTAssertEqual((request.bodyParameters?["client_id"] as? String), "clientid")
        XCTAssertEqual((request.bodyParameters?["client_secret"] as? String), "supersecret")
        XCTAssertEqual(request.bodyParameters?["token"] as? String, "abcd123")
        XCTAssertEqual(request.bodyParameters?["token_type_hint"] as? String, "access_token")
    }
    
    func testIntrospectActiveAccessToken() throws {
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

        var tokenInfo: TokenInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectInactiveAccessToken() throws {
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
        var tokenInfo: TokenInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(tokenInfo?.active, false)
    }
    
    func testIntrospectActiveRefreshToken() throws {
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

        var tokenInfo: TokenInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectActiveIdToken() throws {
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

        var tokenInfo: TokenInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectActiveDeviceSecret() throws {
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

        var tokenInfo: TokenInfo?
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
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(tokenInfo?.subject, "john.doe@example.com")
        XCTAssertEqual(tokenInfo?.active, true)
    }
    
    func testIntrospectFailed() throws {
        let token = Token(id: "TokenId",
                          issuedAt: Date(),
                          tokenType: "Bearer",
                          expiresIn: 300,
                          accessToken: "abcd123",
                          scope: "openid",
                          refreshToken: nil,
                          idToken: nil,
                          deviceSecret: nil,
                          context: Token.Context(configuration: self.configuration,
                                                 clientSettings: []))
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
                XCTAssertEqual(error.localizedDescription,
                               OAuth2Error.network(error: APIClientError.missingResponse).localizedDescription)
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
 
    func testRevoke() throws {
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
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRevokeRequestClientAuthentication() throws {
        let request = try Token.RevokeRequest(openIdConfiguration: openIdConfiguration,
                                              clientAuthentication: .clientSecret("supersecret"),
                                              token: "the-token",
                                              hint: .deviceSecret,
                                              configuration: [:])
        let parameters = try XCTUnwrap(request.bodyParameters as? [String: String])
        XCTAssertEqual(parameters["token"], "the-token")
        XCTAssertEqual(parameters["token_type_hint"], "device_secret")
        XCTAssertEqual(parameters["client_secret"], "supersecret")
    }

    func testRefresh() throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        var newTokens = [Token]()
        
        for _ in 1...4 {
            let expect = expectation(description: "refresh")
            client.refresh(token) { result in
                switch result {
                case .success(let newToken):
                    newTokens.append(newToken)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(newTokens.count, 4)
    }

    func testRefreshRequestClientAuthentication() throws {
        let clientConfiguration = OAuth2Client.Configuration(baseURL: client.configuration.baseURL,
                                                             clientId: client.configuration.clientId,
                                                             scopes: client.configuration.scopes,
                                                             authentication: .clientSecret("supersecret"))
        let request = Token.RefreshRequest(openIdConfiguration: openIdConfiguration,
                                           clientConfiguration: clientConfiguration,
                                           refreshToken: "the-token",
                                           id: "token-id",
                                           configuration: [:])
        let parameters = try XCTUnwrap(request.bodyParameters as? [String: String])
        XCTAssertEqual(parameters["refresh_token"], "the-token")
        XCTAssertEqual(parameters["grant_type"], "refresh_token")
        XCTAssertEqual(parameters["client_secret"], "supersecret")
    }

    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRefreshAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let token = try await client.refresh(token)
        XCTAssertNotNil(token)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRevokeAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        try await client.revoke(token, type: .accessToken)
    }
    #endif
}
