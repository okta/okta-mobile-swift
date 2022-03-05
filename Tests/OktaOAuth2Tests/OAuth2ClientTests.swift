import XCTest
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
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
                                                         pkce: pkce)
        
        urlSession.expect("https://example.com/oauth2/default/v1/token",
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
}
