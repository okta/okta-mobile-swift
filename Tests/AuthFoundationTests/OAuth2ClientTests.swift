import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    
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
}
