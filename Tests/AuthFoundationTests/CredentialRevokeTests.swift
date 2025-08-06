//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation
import Testing
@testable import TestCommon
@testable import AuthFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Suite("Credential revocation")
struct CredentialRevokeTests {
    let token = try! Token(id: "TokenId",
                           issuedAt: Date(),
                           tokenType: "Bearer",
                           expiresIn: 300,
                           accessToken: "abcd123",
                           scope: "openid",
                           refreshToken: "refresh123",
                           idToken: nil,
                           deviceSecret: "device123",
                           context: Token.Context(configuration: .init(issuerURL: URL(string: "https://example.com/oauth2/default")!,
                                                                       clientId: "clientid",
                                                                       scope: "openid"),
                                                  clientSettings: ["client_id": "clientid"]))

    func makeCredential() async throws -> (MockCredentialCoordinator, Credential, URLSessionMock) {
        let coordinator = await MockCredentialCoordinator()
        let credential = await coordinator.credentialDataSource.credential(for: token, coordinator: coordinator)
        let urlSession = try #require(credential.oauth2.session as? URLSessionMock)
        return (coordinator, credential, urlSession)
    }
    
    @Test("Remove credential functionality")
    func testRemove() async throws {
        let (coordinator, credential, _) = try await makeCredential()
        try credential.remove()

        let hasCredential = await coordinator.credentialDataSource.hasCredential(for: token)
        #expect(!hasCredential)
    }
    
    @Test("Revoke all tokens")
    func testRevoke() async throws {
        let (coordinator, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        let token = token
        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))
        }

        try await credential.revoke(type: .all)

        let requests: [String: URLRequest] = urlSession.requests.reduce(into: [:]) { partialResult, request in
            guard let url = request.url,
                  url.absoluteString.starts(with: "https://example.com/oauth2/v1/revoke"),
                  let tokenType = request.bodyString?.urlFormDecoded()["token_type_hint"]
            else {
                return
            }
            
            partialResult[tokenType] = request
        }
        
        #expect(requests["access_token"]?.bodyString ==
                "client_id=clientid&token=abcd123&token_type_hint=access_token")
        #expect(requests["refresh_token"]?.bodyString ==
                "client_id=clientid&token=refresh123&token_type_hint=refresh_token")
        #expect(requests["device_secret"]?.bodyString ==
                "client_id=clientid&token=device123&token_type_hint=device_secret")

        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 0)
            #expect(!coordinator.credentialDataSource.hasCredential(for: token))
        }
    }

    @Test("Revoke access token only")
    func testRevokeAccessToken() async throws {
        let (coordinator, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        let token = token
        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))
        }

        try await credential.revoke(type: .accessToken)

        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))
        }
    }

    @Test("Revoke failure handling")
    func testRevokeFailure() async throws {
        let (_, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: data(for: """
                                        {"error": "invalid_token", "errorDescription": "Invalid token"}
                                    """),
                          statusCode: 400,
                          contentType: "application/json")
        
        let error = await #expect(throws: APIClientError.self) {
            try await credential.revoke(type: .accessToken)
        }
        
        #expect(error == .httpError(OAuth2ServerError(code: "invalid_token",
                                                      description: "Invalid token")))
    }

    @Test("Revoke all tokens comprehensive")
    func testRevokeAll() async throws {
        let (_, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        try await credential.revoke(type: .all)

        let accessTokenRequest = try #require(urlSession.request(matching: .body("token=abcd123")))
        #expect(accessTokenRequest.bodyString == "client_id=clientid&token=abcd123&token_type_hint=access_token")

        let refreshTokenRequest = try #require(urlSession.request(matching: .body("token=refresh123")))
        #expect(refreshTokenRequest.bodyString == "client_id=clientid&token=refresh123&token_type_hint=refresh_token")

        let deviceSecretRequest = try #require(urlSession.request(matching: .body("token=device123")))
        #expect(deviceSecretRequest.bodyString == "client_id=clientid&token=device123&token_type_hint=device_secret")
    }
    
    @Test("Failure after revoke access token")
    func testFailureAfterRevokeAccessToken() async throws {
        let (coordinator, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        let token = token
        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))
        }

        try await CredentialActor.run {
            let storage = try #require(coordinator.tokenStorage as? MockTokenStorage)
            storage.error = CredentialError.metadataConsistency
        }

        try await credential.revoke(type: .accessToken)

        await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))
        }
    }

    @Test("Revoke failure async")
    func testRevokeFailureAsync() async throws {
        let (_, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: data(for: """
                                        {"error": "invalid_token", "errorDescription": "Invalid token"}
                                    """),
                          statusCode: 400,
                          contentType: "application/json")
        
        let error = await #expect(throws: APIClientError.self) {
            try await credential.revoke(type: .accessToken)
        }
        
        #expect(error == .httpError(OAuth2ServerError(code: "invalid_token",
                                                      description: "Invalid token")))
    }
    
    @Test("Failure after revoke access token async")
    func testFailureAfterRevokeAccessTokenAsync() async throws {
        let (coordinator, credential, urlSession) = try await makeCredential()

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        let token = token
        try await CredentialActor.run {
            #expect(coordinator.credentialDataSource.credentialCount == 1)
            #expect(coordinator.credentialDataSource.hasCredential(for: token))

            let storage = try #require(coordinator.tokenStorage as? MockTokenStorage)
            storage.error = OAuth2Error.invalidUrl
        }

        let error = await #expect(throws: OAuth2Error.self) {
            try await credential.revoke()
        }
        
        #expect(error == .invalidUrl)
    }
}
