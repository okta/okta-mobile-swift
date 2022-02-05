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

    func testRefresh() throws {
        urlSession.expect("https://example.com/oauth2/default/v1/token",
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
        urlSession.expect("https://example.com/oauth2/default/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let token = try await client.refresh(token)
        XCTAssertNotNil(token)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRevokeAsync() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/revoke",
                          data: Data())

        try await client.revoke(token, type: .accessToken)
    }
    #endif
}
