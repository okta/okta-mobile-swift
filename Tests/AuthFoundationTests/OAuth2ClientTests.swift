import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    let configuration = OAuth2Client.Configuration(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scopes: "openid")
    var token: Token!

    override func setUpWithError() throws {
        client = OAuth2Client(configuration, session: urlSession)
        
        token = Token(issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(configuration: self.configuration,
                                             clientSettings: [ "client_id": "clientid" ]))
        
        urlSession.requestDelay = 0.1
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

    #if swift(>=5.5.1)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRefreshAsync() async throws {
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let token = try await client.refresh(token)
        XCTAssertNotNil(token)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
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
