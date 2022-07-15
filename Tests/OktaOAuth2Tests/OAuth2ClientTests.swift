import XCTest
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com/oauth2/default")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer, clientId: "theClientId", scopes: "openid profile offline_access", session: urlSession)
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
        
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    func testAuthorizationCodeConstructor() throws {
        let flow = AuthorizationCodeFlow(issuer: issuer,
                                         clientId: "theClientId",
                                         scopes: "openid profile offline_access",
                                         redirectUri: redirectUri)
        XCTAssertNotNil(flow)
    }
    
    func testExchange() throws {
        let pkce = PKCE()
        let request = AuthorizationCodeFlow.TokenRequest(openIdConfiguration: openIdConfiguration,
                                                         clientId: "client_id",
                                                         scope: "openid profile offline_access",
                                                         redirectUri: redirectUri.absoluteString,
                                                         grantType: .authorizationCode,
                                                         grantValue: "abc123",
                                                         pkce: pkce,
                                                         nonce: nil,
                                                         maxAge: nil)
        
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=theClientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")
        
        var token: Token?
        let expect = expectation(description: "network request")
        client.exchange(token: request) { result in
            guard case let .success(apiResponse) = result else {
                XCTFail()
                return
            }
            
            token = apiResponse.result
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.tokenType, "Bearer")
        XCTAssertEqual(token?.expiresIn, 3600)
        XCTAssertEqual(token?.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token?.refreshToken, "therefreshtoken")
        XCTAssertNotNil(token?.idToken)
        XCTAssertEqual(token?.scope, "openid profile offline_access")
    }
    
    func testExchangeFailed() throws {
        let pkce = PKCE()
        client = OAuth2Client(
            baseURL: issuer,
            clientId: "theClientId",
            scopes: "openid profile offline_access",
            session: urlSession
        )

        let request = AuthorizationCodeFlow.TokenRequest(openIdConfiguration: openIdConfiguration,
                                                         clientId: "client_id",
                                                         scope: "openid profile offline_access",
                                                         redirectUri: redirectUri.absoluteString,
                                                         grantType: .authorizationCode,
                                                         grantValue: "abc123",
                                                         pkce: pkce,
                                                         nonce: nil,
                                                         maxAge: nil)

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=theClientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")

        let expect = expectation(description: "network request")
        client.exchange(token: request) { result in
            guard case let .failure(error) = result,
                  case let .validation(error: invalidIssuer) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(invalidIssuer as? JWTError, JWTError.invalidIssuer)
        }
        expect.fulfill()

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testExchangeWhenOpenIdConfigurationIsMissingResponse() throws {
        let pkce = PKCE()
        let request = AuthorizationCodeFlow.TokenRequest(openIdConfiguration: openIdConfiguration,
                                                         clientId: "client_id",
                                                         scope: "openid profile offline_access",
                                                         redirectUri: redirectUri.absoluteString,
                                                         grantType: .authorizationCode,
                                                         grantValue: "abc123",
                                                         pkce: pkce,
                                                         nonce: nil,
                                                         maxAge: nil)

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: nil, statusCode: 500)
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=theClientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"),
                          contentType: "application/json")

        let expect = expectation(description: "network request")
        client.exchange(token: request) { result in
            guard case let .failure(error) = result,
                  case let .serverError(missingResponse) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(missingResponse.localizedDescription, APIClientError.missingResponse.localizedDescription)
        }
        expect.fulfill()

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
}
