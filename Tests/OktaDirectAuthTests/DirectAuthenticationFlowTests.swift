//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaDirectAuth

struct TestStepHandler: StepHandler {
    let flow: OktaDirectAuth.DirectAuthenticationFlow
    let openIdConfiguration: AuthFoundation.OpenIdConfiguration
    let loginHint: String?
    let context: OktaDirectAuth.DirectAuthenticationFlow.Context
    let factor: TestFactor
    let result: (Result<OktaDirectAuth.DirectAuthenticationFlow.Status, OktaDirectAuth.DirectAuthenticationFlowError>)?
    
    func process() async throws -> OktaDirectAuth.DirectAuthenticationFlow.Status {
        switch result {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        case nil:
            throw DirectAuthenticationFlowError.flowNotStarted
        }
    }
}

struct TestFactor: AuthenticationFactor {
    let result: (Result<OktaDirectAuth.DirectAuthenticationFlow.Status, OktaDirectAuth.DirectAuthenticationFlowError>)?
    let exception: (any Error)?
    
    func grantType(currentStatus: DirectAuthenticationFlow.Status?) -> GrantType {
        .implicit
    }
    
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: APIRequestArgument] {
        [:]
    }
    
    func stepHandler(flow: OktaDirectAuth.DirectAuthenticationFlow,
                     openIdConfiguration: AuthFoundation.OpenIdConfiguration,
                     loginHint: String?) async throws -> OktaDirectAuth.StepHandler
    {
        if let exception = exception {
            throw exception
        }
        
        return TestStepHandler(flow: flow,
                               openIdConfiguration: openIdConfiguration,
                               loginHint: loginHint,
                               context: await flow.context!,
                               factor: self,
                               result: result)
    }
}

extension DirectAuthenticationFlow {
    func setContext(_ context: Context?) async {
        self.context = context
    }
}

final class DirectAuthenticationFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.okta.com")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    var flow: DirectAuthenticationFlow!
    
    override func setUpWithError() throws {
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)
        openIdConfiguration = try mock(from: .module,
                                       for: "openid-configuration",
                                       in: "MockResponses")
        flow = client.directAuthenticationFlow()
        
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testDirectAuthSuccess() async throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        let token = Token.mockToken()
        let factor = TestFactor(result: .success(.success(token)), exception: nil)
        await flow.setContext(.init())

        let result = try await flow.runStep(with: factor)
        XCTAssertEqual(result, .success(token))
    }
    
    func testDirectAuthFailure() async throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let factor = TestFactor(result: .failure(.pollingTimeoutExceeded), exception: nil)
        await flow.setContext(.init())
        let error = await XCTAssertThrowsErrorAsync(try await flow.runStep(with: factor))
        XCTAssertEqual(error as? DirectAuthenticationFlowError, .pollingTimeoutExceeded)
    }

    func testDirectAuthException() async throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let factor = TestFactor(result: nil, exception: APIClientError.invalidRequestData)
        await flow.setContext(.init())
        let error = await XCTAssertThrowsErrorAsync(try await flow.runStep(with: factor))
        XCTAssertEqual(error as? APIClientError, .invalidRequestData)
    }
}
