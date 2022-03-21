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

final class CredentialRefreshTests: XCTestCase {
    let coordinator = MockCredentialCoordinator()

    func credential(for token: Token, expectAPICalls: Bool = true) throws -> Credential {
        let credential = coordinator.credentialDataSource.credential(for: token, coordinator: coordinator)
        
        if expectAPICalls {
            let urlSession = credential.oauth2.session as! URLSessionMock
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.com/oauth2/v1/token",
                              data: try data(from: .module, for: "token", in: "MockResponses"))
        }
        
        return credential
    }
    
    func testRefresh() throws {
        let credential = try credential(for: Token.simpleMockToken)

        let expect = expectation(description: "refresh")
        credential.refresh { result in
            switch result {
            case .success(let newToken):
                XCTAssertNotNil(newToken)
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        XCTAssertTrue(credential.token.isRefreshing)

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
    }

    func testRefreshIfNeededExpired() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 6000))
        let expect = expectation(description: "refresh")
        credential.refreshIfNeeded() { result in
            switch result {
            case .success(let newToken):
                XCTAssertNotNil(newToken)
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        XCTAssertTrue(credential.token.isRefreshing)

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
    }

    func testRefreshIfNeededWithinGraceInterval() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 0),
                                           expectAPICalls: false)
        let expect = expectation(description: "refresh")
        credential.refreshIfNeeded() { result in
            switch result {
            case .success(let newToken):
                XCTAssertNotNil(newToken)
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        XCTAssertFalse(credential.token.isRefreshing)

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
    }

    func testRefreshIfNeededOutsideGraceInterval() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 3500))
        let expect = expectation(description: "refresh")
        credential.refreshIfNeeded() { result in
            switch result {
            case .success(let newToken):
                XCTAssertNotNil(newToken)
            case .failure(let error):
                XCTAssertNil(error)
            }
            expect.fulfill()
        }
        
        XCTAssertTrue(credential.token.isRefreshing)

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
    }

    #if swift(>=5.5.1)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRefreshAsync() async throws {
        let credential = try credential(for: Token.simpleMockToken)
        let token = try await credential.refresh()
        XCTAssertNotNil(token)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRefreshIfNeededExpiredAsync() async throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 6000))
        let token = try await credential.refreshIfNeeded()
        XCTAssertNotNil(token)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRefreshIfNeededWithinGraceIntervalAsync() async throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 0),
                                           expectAPICalls: false)
        let token = try await credential.refreshIfNeeded()
        XCTAssertNotNil(token)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func testRefreshIfNeededOutsideGraceIntervalAsync() async throws {
            let credential = try credential(for: Token.mockToken(issuedOffset: 3500))
        let token = try await credential.refreshIfNeeded()
        XCTAssertNotNil(token)
    }
    #endif
}
