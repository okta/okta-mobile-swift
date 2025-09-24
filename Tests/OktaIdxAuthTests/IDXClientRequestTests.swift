/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdxAuth

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class IDXClientRequestTests: XCTestCase {
    var issuer: URL!
    var redirectUri: URL!
    var client: OAuth2Client!
    var openIdConfiguration: OpenIdConfiguration!
    var pkce: PKCE!
    var context: InteractionCodeFlow.Context!
    let urlSession = URLSessionMock()

    override func setUpWithError() throws {
        issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              session: urlSession)
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
        pkce = try XCTUnwrap(PKCE())
        context = InteractionCodeFlow.Context(recoveryToken: "RecoveryToken",
                                              state: "state",
                                              pkce: pkce,
                                              acrValues: nil,
                                              maxAge: nil,
                                              nonce: nil,
                                              additionalParameters: nil)
    }

    func testInteractRequest() throws {
        let request = try InteractionCodeFlow.InteractRequest(openIdConfiguration: openIdConfiguration,
                                                              clientConfiguration: client.configuration,
                                                              additionalParameters: nil,
                                                              context: context)

        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/oauth2/default/v1/interact")
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded; charset=UTF-8")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json; charset=UTF-8")
        XCTAssertNotNil(urlRequest.allHTTPHeaderFields?["User-Agent"])
        
        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded)
        XCTAssertEqual(data.keys.sorted(), ["client_id", "code_challenge", "code_challenge_method", "recovery_token", "redirect_uri", "response_type", "scope", "state"])
        XCTAssertEqual(data["client_id"], "clientId")
        XCTAssertEqual(data["scope"], "openid+profile")
        XCTAssertEqual(data["code_challenge"], pkce.codeChallenge)
        #if canImport(FoundationNetworking)
        XCTAssertEqual(data["code_challenge_method"], "plain")
        #else
        XCTAssertEqual(data["code_challenge_method"], "S256")
        #endif
        XCTAssertEqual(data["redirect_uri"], "redirect:/uri")
        XCTAssertEqual(data["state"], "state")
        XCTAssertEqual(data["recovery_token"], "RecoveryToken")
    }

    func testInteractRequestWithOrgAuthServer() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com"))
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)
        let request = try InteractionCodeFlow.InteractRequest(openIdConfiguration: openIdConfiguration,
                                                              clientConfiguration: client.configuration,
                                                              additionalParameters: nil,
                                                              context: context)

        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/oauth2/default/v1/interact")
    }

    func testIntrospectRequest() throws {
        context.interactionHandle = "handle"
        let request = try InteractionCodeFlow.IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                                clientConfiguration: client.configuration,
                                                                additionalParameters: nil,
                                                                context: context)
        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/idp/idx/introspect")
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json; charset=UTF-8")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/ion+json; okta-version=1.0.0")
        
        let data = try XCTUnwrap(urlRequest.httpBody?.jsonEncoded() as? [String: String])
        XCTAssertEqual(data.keys.sorted(), ["interactionHandle"])
        XCTAssertEqual(data["interactionHandle"], "handle")
    }
    
    func testRemediationRequest() throws {
        let flowMock = InteractionCodeFlowMock(client: client, redirectUri: redirectUri)
        let response = try XCTUnwrap(Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "identify-single-form-response",
                       in: "MockResponses")))

        let remediation = try XCTUnwrap(response.remediations[.identify])
        remediation["identifier"]?.value = "user@example.com"
        remediation["credentials.passcode"]?.value = "secret"

        let request = try InteractionCodeFlow.RemediationRequest(remediation: remediation)
        
        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://ios-idx-sdk.okta.com/idp/idx/identify")
        
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json; okta-version=1.0.0")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/ion+json; okta-version=1.0.0")
        
        let data = try XCTUnwrap(urlRequest.httpBody?.jsonEncoded())
        XCTAssertEqual(data.keys.sorted(), ["credentials", "identifier", "stateHandle"])
        XCTAssertEqual(data["identifier"] as? String, "user@example.com")
        XCTAssertEqual(data["credentials"] as? [String: String], ["passcode": "secret"])
        XCTAssertEqual(data["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
    }
    
    func testRemediationRequestResponseResult() throws {
        let flowMock = InteractionCodeFlowMock(client: client, redirectUri: redirectUri)
        let response = try XCTUnwrap(Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "identify-single-form-response",
                       in: "MockResponses")))

        let remediation = try XCTUnwrap(response.remediations[.identify])
        let request = try InteractionCodeFlow.RemediationRequest(remediation: remediation)
        
        let challengeUrl = try XCTUnwrap(URL(string: "/idp/idx/challenge/answer", relativeTo: request.url))
        
        XCTAssertEqual(request.resultType(from: try XCTUnwrap(HTTPURLResponse(url: remediation.href,
                                                                              statusCode: 200,
                                                                              httpVersion: "http/1.1",
                                                                              headerFields: nil))),
                       .success)

        XCTAssertEqual(request.resultType(from: try XCTUnwrap(HTTPURLResponse(url: remediation.href,
                                                                              statusCode: 401,
                                                                              httpVersion: "http/1.1",
                                                                              headerFields: nil))),
                       .success)

        XCTAssertEqual(request.resultType(from: try XCTUnwrap(HTTPURLResponse(url: remediation.href,
                                                                              statusCode: 429,
                                                                              httpVersion: "http/1.1",
                                                                              headerFields: nil))),
                       .retry)

        XCTAssertEqual(request.resultType(from: try XCTUnwrap(HTTPURLResponse(url: challengeUrl,
                                                                              statusCode: 429,
                                                                              httpVersion: "http/1.1",
                                                                              headerFields: nil))),
                       .success)
        
        XCTAssertEqual(request.resultType(from: try XCTUnwrap(HTTPURLResponse(url: remediation.href,
                                                                              statusCode: 500,
                                                                              httpVersion: "http/1.1",
                                                                              headerFields: nil))),
                       .error)
    }
    
    func testRedirectURLTokenRequest() throws {
        let openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
        let request = try InteractionCodeFlow.TokenRequest(openIdConfiguration: openIdConfiguration,
                                                           clientConfiguration: client.configuration,
                                                           additionalParameters: nil,
                                                           context: context,
                                                           interactionCode: "interaction_code")
        
        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/oauth2/default/v1/token")

        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded; charset=UTF-8")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json; charset=UTF-8")
        
        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded)
        XCTAssertEqual(data.keys.sorted(), ["client_id", "code_verifier", "grant_type", "interaction_code", "redirect_uri", "scope"])
        XCTAssertEqual(data["client_id"], "clientId")
        XCTAssertEqual(data["interaction_code"], "interaction_code")
        XCTAssertEqual(data["code_verifier"], context.pkce?.codeVerifier)
        XCTAssertEqual(data["grant_type"], "interaction_code")
    }
    
    func testSuccessResponseTokenRequest() throws {
        let context = InteractionCodeFlow.Context(state: "state")
        let flowMock = InteractionCodeFlowMock(context: context, client: client, redirectUri: redirectUri)

        let ion = try IonResponse.jsonDecoder.decode(
            IonForm.self,
            from: data(for: """
                  {
                    "rel": [
                      "create-form"
                    ],
                    "name": "issue",
                    "href": "https://example.com/oauth2/v1/token",
                    "method": "POST",
                    "value": [
                      {
                        "name": "grant_type",
                        "label": "Grant Type",
                        "required": true,
                        "value": "interaction_code"
                      },
                      {
                        "name": "interaction_code",
                        "label": "Interaction Code",
                        "required": true,
                        "value": "the_interaction_code"
                      },
                      {
                        "name": "client_id",
                        "label": "Client Id",
                        "required": true,
                        "value": "clientId"
                      }
                    ],
                    "accepts": "application/x-www-form-urlencoded"
                  }
            """))
        let remediation = try XCTUnwrap(Remediation(flow: flowMock, ion: ion))
        
        let openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))

        let request = try InteractionCodeFlow.SuccessResponseTokenRequest(openIdConfiguration: openIdConfiguration,
                                                                          clientConfiguration: client.configuration,
                                                                          additionalParameters: nil,
                                                                          context: context,
                                                                          successRemediation: remediation)

        let urlRequest = try request.request(for: client)
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let url = urlRequest.url?.absoluteString
        XCTAssertEqual(url, "https://example.com/oauth2/v1/token")

        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded; charset=UTF-8")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept"], "application/json")

        let data = try XCTUnwrap(urlRequest.httpBody?.urlFormEncoded)
        XCTAssertEqual(data.keys.sorted(), ["client_id", "code_verifier", "grant_type", "interaction_code", "redirect_uri", "scope"])
        XCTAssertEqual(data["client_id"], "clientId")
        XCTAssertEqual(data["interaction_code"], "the_interaction_code")
        XCTAssertEqual(data["grant_type"], "interaction_code")
    }
}
