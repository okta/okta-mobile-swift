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
    let currentStatus: OktaDirectAuth.DirectAuthenticationFlow.Status?
    let factor: TestFactor
    let result: (Result<OktaDirectAuth.DirectAuthenticationFlow.Status, OktaDirectAuth.DirectAuthenticationFlowError>)?
    
    func process(completion: @escaping (Result<OktaDirectAuth.DirectAuthenticationFlow.Status, OktaDirectAuth.DirectAuthenticationFlowError>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
}

struct TestFactor: AuthenticationFactor {
    let result: (Result<OktaDirectAuth.DirectAuthenticationFlow.Status, OktaDirectAuth.DirectAuthenticationFlowError>)?
    let exception: (any Error)?
    
    func grantType(currentStatus: DirectAuthenticationFlow.Status?) -> GrantType {
        .implicit
    }
    
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: String] {
        [:]
    }
    
    func stepHandler(flow: OktaDirectAuth.DirectAuthenticationFlow,
                     openIdConfiguration: AuthFoundation.OpenIdConfiguration,
                     loginHint: String?,
                     currentStatus: OktaDirectAuth.DirectAuthenticationFlow.Status?,
                     factor: TestFactor) throws -> OktaDirectAuth.StepHandler
    {
        if let exception = exception {
            throw exception
        }
        
        return TestStepHandler(flow: flow,
                               openIdConfiguration: openIdConfiguration,
                               loginHint: loginHint,
                               currentStatus: currentStatus,
                               factor: factor,
                               result: result)
    }
}

final class DirectAuthenticationFlowTests: XCTestCase {
    let issuer = URL(string: "https://example.okta.com")!
    let urlSession = URLSessionMock()
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    var flow: DirectAuthenticationFlow!
    
    override func setUpWithError() throws {
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
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
    
    func testDirectAuthSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        
        let wait = expectation(description: "run step")
        let token = Token.mockToken()
        let factor = TestFactor(result: .success(.success(token)), exception: nil)
        flow.runStep(with: factor) { result in
            XCTAssertEqual(result, .success(.success(token)))
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testDirectAuthFailure() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let wait = expectation(description: "run step")
        let factor = TestFactor(result: .failure(.pollingTimeoutExceeded), exception: nil)
        flow.runStep(with: factor) { result in
            XCTAssertEqual(result, .failure(.pollingTimeoutExceeded))
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testDirectAuthException() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")

        let wait = expectation(description: "run step")
        let factor = TestFactor(result: nil, exception: APIClientError.invalidRequestData)
        flow.runStep(with: factor) { result in
            XCTAssertEqual(result, .failure(.network(error: .invalidRequestData)))
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
