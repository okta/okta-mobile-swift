//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import XCTest
@testable import TestCommon
@testable import AuthFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor TestFlow: AuthenticationFlow {
    typealias Delegate = AuthenticationDelegate
    
    struct Context: AuthenticationContext, IDTokenValidatorContext {
        var acrValues: [String]?
        
        var nonce: String?
        
        var maxAge: TimeInterval?
        
        func parameters(for category: AuthFoundation.OAuth2APIRequestCategory) -> [String : any AuthFoundation.APIRequestArgument]? {
            nil
        }
    }

    let client: OAuth2Client
    let additionalParameters: [String: any APIRequestArgument]?
    nonisolated let delegateCollection = DelegateCollection<any Delegate>()

    init(client: OAuth2Client,
         additionalParameters: [String: any APIRequestArgument]?) throws
    {
        self.client = client
        self.additionalParameters = additionalParameters
    }
    
    var context: Context?
    var isAuthenticating: Bool = false
    
    func reset() {
        isAuthenticating = false
        context = nil
    }

    func setContext(_ context: Context?) async {
        self.context = context
    }
}

final class AuthenticationFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.com")!
    var urlSession: URLSessionMock!
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")

    override func setUpWithError() throws {
        urlSession = URLSessionMock()
        client = OAuth2Client(configuration, session: urlSession)

        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testInitializer() throws {
        let url = try fileUrl(from: .module, for: "LegacyFormat.plist", in: "ConfigResources")
        let flow = try TestFlow(plist: url)
        
        XCTAssertEqual(flow.client.configuration.clientId, "0oaasdf1234")
    }
    
    func testValidatorContextHandling() async throws {
        let flow = try TestFlow(client: client, additionalParameters: nil)
        await flow.setContext(.init(acrValues: [], nonce: "abcd123", maxAge: 60))
        
        XCTAssertEqual(flow.nonce, "abcd123")
        XCTAssertEqual(flow.maxAge, 60.0)
    }
}
