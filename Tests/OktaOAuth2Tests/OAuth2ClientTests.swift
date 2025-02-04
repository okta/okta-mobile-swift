import XCTest
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com/oauth2/default")!
    let redirectUri = URL(string: "com.example:/callback")!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    
    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        client = OAuth2Client(issuerURL: issuer, clientId: "theClientId", scope: "openid profile offline_access", session: urlSession)
        
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testAuthorizationCodeConstructor() throws {
        let flow = AuthorizationCodeFlow(issuerURL: issuer,
                                         clientId: "theClientId",
                                         scope: "openid profile offline_access",
                                         redirectUri: redirectUri)
        XCTAssertNotNil(flow)
    }
    
    func testExchange() throws {
        let pkce = try XCTUnwrap(PKCE())
        let (openIdConfiguration, openIdData) = try openIdConfiguration()
        let clientConfiguration = try OAuth2Client.Configuration(domain: "example.com",
                                                                 clientId: "theClientId",
                                                                 scope: "openid profile offline_access",
                                                                 redirectUri: redirectUri.absoluteString)
        let context = AuthorizationCodeFlow.Context(pkce: pkce,
                                                    nonce: .nonce(),
                                                    maxAge: nil,
                                                    acrValues: nil,
                                                    state: "state",
                                                    additionalParameters: nil)
        let request = try AuthorizationCodeFlow.TokenRequest(
            openIdConfiguration: openIdConfiguration,
            clientConfiguration: clientConfiguration,
            additionalParameters: nil,
            context: context,
            authorizationCode: "abc123")

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: openIdData,
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
        XCTAssertEqual(try XCTUnwrap(urlSession.formDecodedBody(matching: "/v1/token")), [
            "grant_type": "authorization_code",
            "code_verifier": pkce.codeVerifier,
            "code": "abc123",
            "scope": "openid+profile+offline_access",
            "redirect_uri": "com.example:/callback",
            "client_id": "theClientId"
        ])
        
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.tokenType, "Bearer")
        XCTAssertEqual(token?.expiresIn, 3600)
        XCTAssertEqual(token?.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token?.refreshToken, "therefreshtoken")
        XCTAssertNotNil(token?.idToken)
        XCTAssertEqual(token?.scope, "openid profile offline_access")
    }
    
    func testExchangeFailed() throws {
        let pkce = try XCTUnwrap(PKCE())
        Token.idTokenValidator = MockIDTokenValidator(error: .invalidIssuer)
        let (openIdConfiguration, openIdData) = try openIdConfiguration(named: "openid-configuration-invalid-issuer")
        let clientConfiguration = try OAuth2Client.Configuration(domain: "example.com",
                                                                 clientId: "theClientId",
                                                                 scope: "openid profile offline_access",
                                                                 redirectUri: redirectUri.absoluteString)
        let context = AuthorizationCodeFlow.Context(pkce: pkce,
                                                    nonce: .nonce(),
                                                    maxAge: nil,
                                                    acrValues: nil,
                                                    state: "state",
                                                    additionalParameters: nil)
        let request = try AuthorizationCodeFlow.TokenRequest(
            openIdConfiguration: openIdConfiguration,
            clientConfiguration: clientConfiguration,
            additionalParameters: nil,
            context: context,
            authorizationCode: "abc123")

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: openIdData,
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
                XCTFail("Did not receive an expected validation failure. \(result)")
                return
            }
            XCTAssertEqual(invalidIssuer as? JWTError, JWTError.invalidIssuer)
            expect.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(urlSession.formDecodedBody(matching: "/v1/token"), [
            "grant_type": "authorization_code",
            "code_verifier": pkce.codeVerifier,
            "code": "abc123",
            "scope": "openid+profile+offline_access",
            "redirect_uri": "com.example:/callback",
            "client_id": "theClientId"
        ])
    }
}
