import XCTest
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer, session: urlSession)
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
        let request = TokenRequest(clientId: "client_id",
                                   clientSecret: nil,
                                   redirectUri: redirectUri.absoluteString,
                                   grantType: .authorizationCode,
                                   grantValue: "abc123",
                                   pkce: pkce)
        
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: """
                            {
                               "token_type": "Bearer",
                               "expires_in": 3600,
                               "access_token": "theaccesstoken",
                               "scope": "openid profile offline_access",
                               "refresh_token": "therefreshtoken",
                               "id_token": "theidtoken"
                             }
                            """.data(using: .utf8),
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
        XCTAssertEqual(token?.accessToken, "theaccesstoken")
        XCTAssertEqual(token?.refreshToken, "therefreshtoken")
        XCTAssertEqual(token?.idToken, "theidtoken")
        XCTAssertEqual(token?.scope, "openid profile offline_access")
    }

    func testOpenIDConfiguration() throws {
        try urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: data(for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
        
        var config: OpenIdConfiguration?
        let expect = expectation(description: "network request")
        client.fetchOpenIdConfiguration() { result in
            guard case let .success(apiResponse) = result else {
                XCTFail()
                return
            }
            
            config = apiResponse.result
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.authorizationEndpoint.absoluteString,
                       "https://example.okta.com/oauth2/v1/authorize")
    }
}
