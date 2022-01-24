import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    let token = Token(issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(baseURL: URL(string: "https://example.com")!,
                                             clientSettings: [ "client_id": "clientid" ]))

    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer, session: urlSession)
    }

    func testOpenIDConfiguration() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
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
    
    func testRevoke() throws {
        urlSession.expect("https://example.com/oauth2/default/v1/revoke",
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
}
