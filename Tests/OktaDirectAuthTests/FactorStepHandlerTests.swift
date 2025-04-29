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
    
    // MARK: - Password Steps
    func assertPasswordStepHandler(factor: some AuthenticationFactor,
                                   loginHint: String?,
                                   bodyParams: [String: String]) async throws
    {
        let context = DirectAuthenticationFlow.Context()
        await flow.setContext(context)
        let handler = try await factor.stepHandler(flow: flow,
                                                   openIdConfiguration: openIdConfiguration,
                                                   loginHint: loginHint)
        let tokenStepHandler = try XCTUnwrap(handler as? TokenStepHandler)
        let request = try XCTUnwrap(tokenStepHandler.request as? TokenRequest)
        XCTAssertEqual(request.clientConfiguration.clientId, client.configuration.clientId)
        
        if let loginHint = loginHint {
            XCTAssertEqual(request.loginHint, loginHint)
        } else {
            XCTAssertNil(request.loginHint)
        }
        
        XCTAssertEqual(request.context, context)
        XCTAssertEqual(request.bodyParameters?.stringComponents, bodyParams)
    }
    
    func testPrimaryPasswordStepHandler() async throws {
        try await assertPasswordStepHandler(
            factor: PrimaryFactor.password("foo"),
            loginHint: "jane.doe@example.com",
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.$scope.rawValue,
                "grant_type": "password",
                "username": "jane.doe@example.com",
                "password": "foo",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    func testPrimaryOTPStepHandler() async throws {
        try await assertPasswordStepHandler(
            factor: PrimaryFactor.otp(code: "123456"),
            loginHint: "jane.doe@example.com",
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.$scope.rawValue,
                "grant_type": "urn:okta:params:oauth:grant-type:otp",
                "login_hint": "jane.doe@example.com",
                "otp": "123456",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    func testSecondaryStepHandler() async throws {
        try await assertPasswordStepHandler(
            factor: SecondaryFactor.otp(code: "123456"),
            loginHint: nil,
            bodyParams: [
                "client_id": client.configuration.clientId,
                "scope": client.configuration.$scope.rawValue,
                "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
                "otp": "123456",
                "grant_types_supported": "password urn:okta:params:oauth:grant-type:oob urn:okta:params:oauth:grant-type:otp http://auth0.com/oauth/grant-type/mfa-oob http://auth0.com/oauth/grant-type/mfa-otp urn:okta:params:oauth:grant-type:webauthn urn:okta:params:oauth:grant-type:mfa-webauthn",
            ])
    }
    
    // MARK: OOB Steps
    func assertOOBStepHandler<T: AuthenticationFactor>(factor: T,
                                                       loginHint: String?) async throws
    {
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(flow: flow,
                                                   openIdConfiguration: openIdConfiguration,
                                                   loginHint: loginHint)
        let tokenStepHandler = try XCTUnwrap(handler as? OOBStepHandler<T>)
        if let loginHint = loginHint {
            XCTAssertEqual(tokenStepHandler.loginHint, loginHint)
        } else {
            XCTAssertNil(tokenStepHandler.loginHint)
        }
    }
    
    func testPrimaryOOBStepHandler() async throws {
        try await assertOOBStepHandler(
            factor: PrimaryFactor.oob(channel: .push),
            loginHint: "jane.doe@example.com")
    }

    func testSecondaryOOBStepHandler() async throws {
        try await assertOOBStepHandler(
            factor: PrimaryFactor.oob(channel: .push),
            loginHint: nil)
    }

    // MARK: - Token Process Flow
    func testPrimaryTokenSuccess() async throws {
        urlSession.expect("https://example.okta.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.okta.com/oauth2/v1/token",
                          data: try data(from: .module, for: "token", in: "MockResponses"))
        
        let factor = PrimaryFactor.password("SuperSecret")
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let status = try await flow.process(stepHandler: handler)
        switch status {
        case .success(_): break
        case .mfaRequired(_), .continuation(_):
            XCTFail("Did not receive a success response")
        }
    }
    
    func testPrimaryTokenMFARequired() async throws {
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
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let status = try await flow.process(stepHandler: handler)
        switch status {
        case .success(_), .continuation(_):
            XCTFail("Did not receive a mfa_required response")
        case .mfaRequired(let context):
            XCTAssertEqual(context.mfaToken, "abcd1234")
            XCTAssertEqual(context.supportedChallengeTypes, [.otpMFA, .oobMFA])
        }
    }
    
    // MARK: OOB Process Flow
    func testPrimaryOOBSuccess() async throws {
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
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let status = try await flow.process(stepHandler: handler)
        switch status {
        case .success(_): break
        case .mfaRequired(_), .continuation(_):
            XCTFail("Did not receive a success response")
        }
    }

    func testPrimaryOOBBindingTransferSuccess() async throws {
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
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let status = try await flow.process(stepHandler: handler)
        guard case let .continuation(continuation) = status
        else {
            XCTFail("Did not receive binding update in result: \(status)")
            return
        }
        
        XCTAssertEqual(continuation.bindingContext?.oobResponse.oobCode,
                       "1c266114-a1be-4252-8ad1-04986c5b9ac1")

        guard case let .transfer(_, code: code) = continuation else {
            XCTFail("Did not receive transfer code: \(continuation)")
            return
        }

        XCTAssertEqual(code, "12")

        let resumeFactor = SecondaryFactor.oob(channel: .push)
        let resumeHandler = try await resumeFactor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration)
        let resumeStatus = try await flow.process(stepHandler: resumeHandler)

        guard case .success(_) = resumeStatus else {
            XCTFail("Did not receive token")
            return
        }

        let tokenBody = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.url?.lastPathComponent == "token"
        }).flatMap({ $0.bodyString }))
        let tokenParams = tokenBody.urlFormDecoded()
        
        XCTAssertEqual(tokenParams["grant_type"],
                       "urn:okta:params:oauth:grant-type:oob")
    }

    func testPrimaryOOBBindingTransferFail() async throws {
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
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let error = await XCTAssertThrowsErrorAsync(try await flow.process(stepHandler: handler))
        XCTAssertEqual(error as? DirectAuthenticationFlowError, .bindingCodeMissing)
    }
    
    func testPrimaryOOBMFARequired() async throws {
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
        await flow.setContext(.init())
        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration,
            loginHint: "jane.doe@example.com")
        
        let status = try await flow.process(stepHandler: handler)
        guard case let .mfaRequired(context) = status
        else {
            XCTFail("Did not receive a mfa_required response: \(status)")
            return
        }

        XCTAssertEqual(context.mfaToken, "abcd1234")
        XCTAssertEqual(context.supportedChallengeTypes, [.otpMFA, .oobMFA])
    }
    
    func testSecondaryOOBSuccess() async throws {
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
        var context = DirectAuthenticationFlow.Context()
        context.currentStatus = .mfaRequired(.init(supportedChallengeTypes: nil,
                                                   mfaToken: "abcd1234"))
        await flow.setContext(context)

        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration)

        let status = try await flow.process(stepHandler: handler)
        guard case .success(_) = status else {
            XCTFail("Did not receive a success response")
            return
        }
    }

    func testSecondaryOOBBindingTransferSuccess() async throws {
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
        var context = DirectAuthenticationFlow.Context()
        context.currentStatus = .mfaRequired(.init(supportedChallengeTypes: nil,
                                                   mfaToken: "abcd1234"))
        await flow.setContext(context)

        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration)

        let status = try await flow.process(stepHandler: handler)
        guard case let .continuation(continuation) = status
        else {
            XCTFail("Did not receive binding update in result: \(status)")
            return
        }

        XCTAssertEqual(continuation.bindingContext?.oobResponse.oobCode,
                       "1c266114-a1be-4252-8ad1-04986c5b9ac1")

        guard case let .transfer(_, code: code) = continuation else {
            XCTFail("Did not receive binding update in result: \(continuation)")
            return
        }
        XCTAssertEqual(code, "12")

        let resumeHandler = try await factor.stepHandler(
            flow: self.flow,
            openIdConfiguration: self.openIdConfiguration)
        let resumeStatus = try await flow.process(stepHandler: resumeHandler)
        guard case .success(_) = resumeStatus else {
            XCTFail("Did not receive a success response")
            return
        }
    }

    func testSecondaryOOBBindingTransferFail() async throws {
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
        var context = DirectAuthenticationFlow.Context()
        context.currentStatus = .mfaRequired(.init(supportedChallengeTypes: nil,
                                                   mfaToken: "abcd1234"))
        await flow.setContext(context)

        let handler = try await factor.stepHandler(
            flow: flow,
            openIdConfiguration: openIdConfiguration)

        let error = await XCTAssertThrowsErrorAsync(try await flow.process(stepHandler: handler))
        XCTAssertEqual(error as? DirectAuthenticationFlowError, .bindingCodeMissing)
    }
}
