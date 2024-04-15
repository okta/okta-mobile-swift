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

final class FactorStepHandlerTests: XCTestCase {
    typealias PrimaryFactor = DirectAuthenticationFlow.PrimaryFactor
    typealias SecondaryFactor = DirectAuthenticationFlow.SecondaryFactor
    
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
    
    // MARK: - Password Steps
    func assertPasswordStepHandler(factor: some AuthenticationFactor,
                                   loginHint: String?,
                                   bodyParams: [String: String]) throws
    {
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: loginHint,
                                             currentStatus: nil,
                                             factor: factor)
        let tokenStepHandler = try XCTUnwrap(handler as? TokenStepHandler)
        let request = try XCTUnwrap(tokenStepHandler.request as? TokenRequest)
        XCTAssertEqual(request.clientId, client.configuration.clientId)
        
        if let loginHint = loginHint {
            XCTAssertEqual(request.loginHint, loginHint)
        } else {
            XCTAssertNil(request.loginHint)
        }
        
        XCTAssertEqual(request.grantTypesSupported, flow.supportedGrantTypes)
        XCTAssertEqual(request.bodyParameters as? [String: String], bodyParams)
    }
    
    func testPrimaryPasswordStepHandler() throws {
        try assertPasswordStepHandler(
            factor: PrimaryFactor.password("foo"),
            loginHint: "jane.doe@example.com",
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.scopes,
                "grant_type": "password",
                "username": "jane.doe@example.com",
                "password": "foo",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    func testPrimaryOTPStepHandler() throws {
        try assertPasswordStepHandler(
            factor: PrimaryFactor.otp(code: "123456"),
            loginHint: "jane.doe@example.com",
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.scopes,
                "grant_type": "urn:okta:params:oauth:grant-type:otp",
                "login_hint": "jane.doe@example.com",
                "otp": "123456",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    func testSecondaryStepHandler() throws {
        try assertPasswordStepHandler(
            factor: SecondaryFactor.otp(code: "123456"),
            loginHint: nil,
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.scopes,
                "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
                "otp": "123456",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    // MARK: OOB Steps
    func assertOOBStepHandler<T: AuthenticationFactor>(factor: T,
                                                       loginHint: String?) throws
    {
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: loginHint,
                                             currentStatus: nil,
                                             factor: factor)
        let tokenStepHandler = try XCTUnwrap(handler as? OOBStepHandler<T>)
        if let loginHint = loginHint {
            XCTAssertEqual(tokenStepHandler.loginHint, loginHint)
        } else {
            XCTAssertNil(tokenStepHandler.loginHint)
        }
    }
    
    func testPrimaryOOBStepHandler() throws {
        try assertOOBStepHandler(factor: PrimaryFactor.oob(channel: .push),
                                 loginHint: "jane.doe@example.com")
    }
    
    func testSecondaryOOBStepHandler() throws {
        try assertOOBStepHandler(factor: PrimaryFactor.oob(channel: .push),
                                 loginHint: nil)
    }
    
    // MARK: - Token Process Flow
    func testPrimaryTokenSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let factor = PrimaryFactor.password("SuperSecret")
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let wait = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(let status):
                switch status {
                case .success(_): break
                case .mfaRequired(_), .bindingUpdate(_), .webAuthn(request: _):
                    XCTFail("Did not receive a success response")
                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testPrimaryTokenMFARequired() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token-mfa_required", in: "MockResponses"),
                          statusCode: 400)
        
        let factor = PrimaryFactor.password("SuperSecret")
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let wait = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(let status):
                switch status {
                case .success(_), .bindingUpdate(_), .webAuthn(request: _):
                    XCTFail("Did not receive a mfa_required response")
                case .mfaRequired(let context):
                    XCTAssertEqual(context.mfaToken, "abcd1234")
                    XCTAssertEqual(context.supportedChallengeTypes, [.otpMFA, .oobMFA])
                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // MARK: OOB Process Flow
    func testPrimaryOOBSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/primary-authenticate",
                          data: try data(from: .module, for: "primary-authenticate", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let factor = PrimaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let wait = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(let status):
                switch status {
                case .success(_): break
                case .mfaRequired(_), .bindingUpdate(_), .webAuthn(request: _):
                    XCTFail("Did not receive a success response")
                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testPrimaryOOBBindingTransferSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/primary-authenticate",
                          data: try data(from: .module, for: "primary-authenticate-binding-transfer", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        let factor = PrimaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let processExpectation = expectation(description: "process")
        handler.process { result in
            guard case .success(let status) = result,
                  case .bindingUpdate(let context) = status else {
                XCTFail("Did not receive binding update in result: \(result)")
                return
            }
            switch context.update {
            case .transfer(let code):
                XCTAssertEqual(code, "12")
                do {
                    let factor = SecondaryFactor.oob(channel: .push)
                    let resumeHandler = try factor.stepHandler(flow: self.flow,
                                                               openIdConfiguration: self.openIdConfiguration,
                                                               currentStatus: status,
                                                               factor: factor)
                    self.assertGettingTokenAfterBindingTransfer(using: resumeHandler)
                } catch {
                    XCTFail("Did not expect error creating step handler: \(error)")
                }
            }
            XCTAssertEqual(context.oobResponse.oobCode, "1c266114-a1be-4252-8ad1-04986c5b9ac1")
            processExpectation.fulfill()
        }
        wait(for: [processExpectation], timeout: 5)
        
        let tokenBody = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.url?.lastPathComponent == "token"
        }).flatMap({ $0.bodyString }))
        let tokenParams = tokenBody.urlFormDecoded()
        
        XCTAssertEqual(tokenParams["grant_type"],
                       "urn:okta:params:oauth:grant-type:oob")
    }

    func testPrimaryOOBBindingTransferFail() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/primary-authenticate",
                          data: try data(from: .module, for: "primary-authenticate-binding-transfer-missingCode", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        let factor = PrimaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let processExpectation = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(_):
                XCTFail("Not expecting success")
            case .failure(let error):
                XCTAssertEqual(error, .bindingCodeMissing)
            }
            processExpectation.fulfill()
        }
        wait(for: [processExpectation], timeout: 5)
    }
    
    func testPrimaryOOBMFARequired() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/primary-authenticate",
                          data: try data(from: .module, for: "primary-authenticate", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token-mfa_required", in: "MockResponses"),
                          statusCode: 400)
        
        let factor = PrimaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             loginHint: "jane.doe@example.com",
                                             factor: factor)
        
        let wait = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(let status):
                switch status {
                case .success(_), .bindingUpdate(_), .webAuthn(request: _):
                    XCTFail("Did not receive a mfa_required response")
                case .mfaRequired(let context):
                    XCTAssertEqual(context.mfaToken, "abcd1234")
                    XCTAssertEqual(context.supportedChallengeTypes, [.otpMFA, .oobMFA])
                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testSecondaryOOBSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/challenge",
                          data: try data(from: .module, for: "challenge-oob", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        let factor = SecondaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             currentStatus: .mfaRequired(.init(supportedChallengeTypes: nil,
                                                                               mfaToken: "abcd1234")),
                                             factor: factor)

        let wait = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(let status):
                switch status {
                case .success(_): break
                case .mfaRequired(_), .bindingUpdate(_), .webAuthn(request: _):
                    XCTFail("Did not receive a success response")
                }
            case .failure(let error):
                XCTAssertNil(error)
            }
            wait.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testSecondaryOOBBindingTransferSuccess() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/challenge",
                          data: try data(from: .module, for: "challenge-oob-binding-transfer", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        let factor = SecondaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             currentStatus: .mfaRequired(.init(supportedChallengeTypes: nil,
                                                                               mfaToken: "abcd1234")),
                                             factor: factor)

        let processExpectation = expectation(description: "process")
        handler.process { result in
            guard case .success(let status) = result,
                  case .bindingUpdate(let context) = status else {
                XCTFail("Did not receive binding update in result: \(result)")
                return
            }
            switch context.update {
            case .transfer(let code):
                XCTAssertEqual(code, "12")
                do {
                    let resumeHandler = try factor.stepHandler(flow: self.flow,
                                                               openIdConfiguration: self.openIdConfiguration,
                                                               currentStatus: status,
                                                               factor: factor)
                    self.assertGettingTokenAfterBindingTransfer(using: resumeHandler)
                } catch {
                    XCTFail("Did not expect error creating step handler: \(error)")
                }
            }
            XCTAssertEqual(context.oobResponse.oobCode, "1c266114-a1be-4252-8ad1-04986c5b9ac1")
            processExpectation.fulfill()
        }
        wait(for: [processExpectation], timeout: 5)
    }

    func testSecondaryOOBBindingTransferFail() throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/challenge",
                          data: try data(from: .module, for: "challenge-oob-binding-transfer-missingCode", in: "MockResponses"))
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))

        let factor = SecondaryFactor.oob(channel: .push)
        let handler = try factor.stepHandler(flow: flow,
                                             openIdConfiguration: openIdConfiguration,
                                             currentStatus: .mfaRequired(.init(supportedChallengeTypes: nil,
                                                                               mfaToken: "abcd1234")),
                                             factor: factor)

        let processExpectation = expectation(description: "process")
        handler.process { result in
            switch result {
            case .success(_):
                XCTFail("Not expecting success")
            case .failure(let error):
                XCTAssertEqual(error.errorDescription, DirectAuthenticationFlowError.bindingCodeMissing.errorDescription)
            }
            processExpectation.fulfill()
        }
        wait(for: [processExpectation], timeout: 5)
    }

    private func assertGettingTokenAfterBindingTransfer(using handler: StepHandler) {
        let tokenExpectation = expectation(description: "get token")
        handler.process { result in
            guard case .success(let status) = result,
                  case .success(_) = status else {
                XCTFail("Did not receive token")
                return
            }
            tokenExpectation.fulfill()
        }
        wait(for: [tokenExpectation], timeout: 2.0)
    }
}
