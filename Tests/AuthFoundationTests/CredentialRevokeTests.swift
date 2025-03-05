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
        
        let requests: [String: URLRequest] = urlSession.requests.reduce(into: [:]) { partialResult, request in
            guard let url = request.url,
                  url.absoluteString.starts(with: "https://example.com/oauth2/v1/revoke"),
                  let tokenType = request.bodyString?.urlFormDecoded()["token_type_hint"]
            else {
                return
            }
            
            partialResult[tokenType] = request
        }
        
        XCTAssertEqual(try XCTUnwrap(requests["access_token"]).bodyString,
                       "client_id=clientid&token=abcd123&token_type_hint=access_token")
        XCTAssertEqual(try XCTUnwrap(requests["refresh_token"]).bodyString,
                       "client_id=clientid&token=refresh123&token_type_hint=refresh_token")
        XCTAssertEqual(try XCTUnwrap(requests["device_secret"]).bodyString,
                       "client_id=clientid&token=device123&token_type_hint=device_secret")

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
                guard case let .server(error: oauth2Error) = error
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
                       "client_id=clientid&token=abcd123&token_type_hint=access_token")
        XCTAssertEqual(refreshTokenRequest.bodyString,
                       "client_id=clientid&token=refresh123&token_type_hint=refresh_token")
        XCTAssertEqual(deviceSecretRequest.bodyString,
                       "client_id=clientid&token=device123&token_type_hint=device_secret")
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
        } catch let error as APIClientError {
            guard case let .httpError(serverError) = error,
                  let oauth2Error = serverError as? OAuth2ServerError
            else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(oauth2Error.code, .invalidToken)
        } catch {
            XCTFail()
        }
    }
    
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
}
