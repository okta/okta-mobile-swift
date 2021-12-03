import XCTest
@testable import OktaOAuth2

final class OAuth2ClientTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "com.example:/callback")!

    func testAuthorizationCodeConstructor() throws {
        let flow = AuthorizationCodeFlow(issuer: issuer,
                                         clientId: "theClientId",
                                         scopes: "openid profile offline_access",
                                         redirectUri: redirectUri)
        XCTAssertNotNil(flow)
    }
}
