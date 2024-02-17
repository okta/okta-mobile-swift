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

import XCTest
@testable import TestCommon
@testable import AuthFoundation

final class CredentialTests: XCTestCase {
    var coordinator: MockCredentialCoordinator!
    var credential: Credential!
    var urlSession: URLSessionMock!

    let token = Token(id: "TokenId",
                      issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: "refresh123",
                      idToken: nil,
                      deviceSecret: "device123",
                      context: Token.Context(configuration: .init(baseURL: URL(string: "https://example.com/oauth2/default")!,
                                                                  clientId: "clientid",
                                                                  scopes: "openid"),
                                             clientSettings: [ "client_id": "foo" ]))

    override func setUpWithError() throws {
        coordinator = MockCredentialCoordinator()
        credential = coordinator.credentialDataSource.credential(for: token, coordinator: coordinator)
        urlSession = credential.oauth2.session as? URLSessionMock
    }
    
    override func tearDownWithError() throws {
        coordinator = nil
        credential = nil
        urlSession = nil
    }

    func testRemove() throws {
        XCTAssertNoThrow(try credential.remove())
        XCTAssertFalse(coordinator.credentialDataSource.hasCredential(for: token))
    }
    
    func testRevoke() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))

        let expect = expectation(description: "network request")
        credential.revoke(type: .all) { result in
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
        
        let revokeRequest = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.url?.absoluteString == "https://example.com/oauth2/v1/revoke"
        }))
        XCTAssertEqual(revokeRequest.bodyString, "client_id=foo&token=abcd123&token_type_hint=access_token")

        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 0)
        XCTAssertFalse(coordinator.credentialDataSource.hasCredential(for: token))
    }

    func testRevokeAccessToken() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))

        let expect = expectation(description: "network request")
        credential.revoke(type: .accessToken) { result in
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

        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))
    }

    func testRevokeFailure() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: data(for: """
                                        {"error": "invalid_token", "errorDescription": "Invalid token"}
                                    """),
                          statusCode: 400,
                          contentType: "application/json")
        
        let expect = expectation(description: "network request")
        credential.revoke(type: .accessToken) { result in
            switch result {
            case .success():
                XCTFail()
                
            case .failure(let error):
                guard case let .network(error: apiError) = error,
                      case let .serverError(serverError) = apiError,
                      let oauth2Error = serverError as? OAuth2ServerError
                else {
                    XCTFail()
                    return
                }

                XCTAssertEqual(oauth2Error.code, .invalidToken)
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }

    func testRevokeAll() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        let expect = expectation(description: "network request")
        credential.revoke(type: .all) { result in
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
        
        let accessTokenRequest = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.bodyString?.contains("abcd123") ?? false
        }))
        let refreshTokenRequest = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.bodyString?.contains("refresh123") ?? false
        }))
        let deviceSecretRequest = try XCTUnwrap(urlSession.requests.first(where: { request in
            request.bodyString?.contains("device123") ?? false
        }))

        XCTAssertEqual(accessTokenRequest.bodyString,
                       "client_id=foo&token=abcd123&token_type_hint=access_token")
        XCTAssertEqual(refreshTokenRequest.bodyString,
                       "client_id=foo&token=refresh123&token_type_hint=refresh_token")
        XCTAssertEqual(deviceSecretRequest.bodyString,
                       "client_id=foo&token=device123&token_type_hint=device_secret")
    }
    
    func testFailureAfterRevokeAccessToken() throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        
        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))

        let storage = try XCTUnwrap(coordinator.tokenStorage as? MockTokenStorage)
        storage.error = CredentialError.metadataConsistency
        
        let expect = expectation(description: "network request")
        credential.revoke(type: .accessToken) { result in
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

        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))
    }

    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRevokeFailureAsync() async throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: data(for: """
                                        {"error": "invalid_token", "errorDescription": "Invalid token"}
                                    """),
                          statusCode: 400,
                          contentType: "application/json")
        
        do {
            try await credential.revoke(type: .accessToken)
        } catch {
            guard let oauth2Error = error as? OAuth2Error,
                  case let .network(error: apiError) = oauth2Error,
                  case let .serverError(serverError) = apiError,
                  let oauth2Error = serverError as? OAuth2ServerError
            else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(oauth2Error.code, .invalidToken)
        }
    }
    
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testFailureAfterRevokeAccessTokenAsync() async throws {
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())
        urlSession.expect("https://example.com/oauth2/v1/revoke",
                          data: Data())

        XCTAssertEqual(coordinator.credentialDataSource.credentialCount, 1)
        XCTAssertTrue(coordinator.credentialDataSource.hasCredential(for: token))

        let storage = try XCTUnwrap(coordinator.tokenStorage as? MockTokenStorage)
        storage.error = OAuth2Error.invalidUrl
        
        do {
            try await credential.revoke()
        } catch let error as OAuth2Error {
            XCTAssert(error == .invalidUrl)
        } catch {
            XCTFail()
        }
    }
    #endif
}
