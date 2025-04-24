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

#if os(Linux)
import FoundationNetworking
#endif

class CredentialRefreshDelegate: OAuth2ClientDelegate, @unchecked Sendable {
    private(set) var refreshCount = 0
    
    func reset() {
        refreshCount = 0
        refreshExpectation = nil
    }
    
    var refreshExpectation: XCTestExpectation?
    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        refreshCount += 1
        
        refreshExpectation?.fulfill()
        refreshExpectation = nil
    }
}

final class CredentialRefreshTests: XCTestCase, OAuth2ClientDelegate, @unchecked Sendable {
    var delegate: CredentialRefreshDelegate!
    var coordinator: CredentialCoordinatorImpl!
    var notificationCenter: NotificationCenter!

    enum APICalls {
        case none
        case error
        case openIdOnly
        case refresh(count: Int, rotate: Bool = false)
    }

    func credential(for token: Token, expectAPICalls: APICalls = .refresh(count: 1), expiresIn: TimeInterval = 3600) async throws -> Credential {
        let credential = try await coordinator.store(token: token, tags: [:], security: Credential.Security.standard)
        credential.oauth2.add(delegate: delegate)
        
        let urlSession = credential.oauth2.session as! URLSessionMock
        urlSession.resetRequests()
        
        switch expectAPICalls {
        case .none: break
        case .openIdOnly:
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")

        case .refresh(let count, let rotate):
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            for index in 1 ... count {
                urlSession.expect("https://example.com/oauth2/v1/token",
                                  data: data(for: """
                {
                   "token_type": "Bearer",
                   "expires_in": \(expiresIn),
                   "access_token": "\(String.mockAccessToken)",
                   "scope": "openid profile offline_access",
                   "refresh_token": "therefreshtoken\(rotate ? "-\(index)" : "")",
                   "id_token": "\(String.mockIdToken)"
                 }
                """))
            }
            
        case .error:
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.com/oauth2/v1/token",
                              data: nil,
                              statusCode: 500)
        }
        
        return credential
    }

    override func setUp() async throws {
        await CredentialActor.run {
            notificationCenter = NotificationCenter()
            coordinator = CredentialCoordinatorImpl()
            coordinator.tokenStorage = MockTokenStorage()
            coordinator.credentialDataSource = MockCredentialDataSource()
        }
        delegate = CredentialRefreshDelegate()
    }

    override func tearDown() async throws {
        notificationCenter = nil
        coordinator = nil
        delegate = nil
    }

    func taskData(_ block: () async throws -> Void) async rethrows {
        try await TaskData.$notificationCenter.withValue(notificationCenter) {
            try await TaskData.$coordinator.withValue(coordinator) {
                try await block()
            }
        }
    }

    func testRefresh() async throws {
        try await taskData {
            let credential = try await credential(for: Token.simpleMockToken)

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
            await fulfillment(of: [expect], timeout: 3.0)

            XCTAssertFalse(credential.token.isRefreshing)
            XCTAssertEqual(delegate.refreshCount, 1)
        }
    }

    func testRefreshFailed() async throws {
        try await taskData {
            let notification = NotificationRecorder(center: notificationCenter,
                                                    observing: [.credentialRefreshFailed, .tokenRefreshFailed])
            let credential = try await credential(for: Token.simpleMockToken, expectAPICalls: .error)

            let expect = expectation(description: "refresh")
            credential.refresh { result in
                switch result {
                case .success(_):
                    XCTFail("Did not expect a success response")
                case .failure(let error):
                    XCTAssertNotNil(error)
                }
                expect.fulfill()
            }

            await fulfillment(of: [expect], timeout: 3.0)

            // Need to wait for the async notification dispatch
            usleep(useconds_t(2000))

            XCTAssertEqual(notification.notifications.count, 2)
            let tokenNotification = try XCTUnwrap(notification.notifications(for: .tokenRefreshFailed).first)
            XCTAssertEqual(tokenNotification.object as? Token, credential.token)
            XCTAssertNotNil(tokenNotification.userInfo?["error"])

            let credentialNotification = try XCTUnwrap(notification.notifications(for: .credentialRefreshFailed).first)
            XCTAssertEqual(credentialNotification.object as? Credential, credential)
            XCTAssertNotNil(credentialNotification.userInfo?["error"])
        }
    }
    
    func testRefreshWithoutRefreshToken() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(id: "TokenID",
                                                                       refreshToken: nil))

            let expect = expectation(description: "refresh")
            credential.refresh { result in
                switch result {
                case .success(_):
                    XCTFail("Did not expect a success response")
                case .failure(let error):
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, .missingToken(type: .refreshToken))
                }
                expect.fulfill()
            }

            await fulfillment(of: [expect], timeout: 3.0)
        }
    }

    func testRefreshWithoutOptionalValues() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(id: "TokenID",
                                                                       deviceSecret: "theDeviceSecret"))

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
            await fulfillment(of: [expect], timeout: 3.0)

            XCTAssertEqual(credential.token.deviceSecret, "theDeviceSecret")
        }
    }

    func testRefreshIfNeededExpired() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 6000))
            let expect = expectation(description: "refresh")
            credential.refreshIfNeeded(graceInterval: 300) { result in
                switch result {
                case .success(let newToken):
                    XCTAssertNotNil(newToken)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }

            await fulfillment(of: [expect], timeout: 3.0)

            XCTAssertFalse(credential.token.isRefreshing)
            XCTAssertEqual(delegate.refreshCount, 1)
        }
    }

    func testRefreshIfNeededWithinGraceInterval() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 0),
                                                  expectAPICalls: .none)
            let expect = expectation(description: "refresh")
            credential.refreshIfNeeded(graceInterval: 300) { result in
                switch result {
                case .success(let newToken):
                    XCTAssertNotNil(newToken)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }

            XCTAssertFalse(credential.token.isRefreshing)

            await fulfillment(of: [expect], timeout: 3.0)

            XCTAssertFalse(credential.token.isRefreshing)
            XCTAssertEqual(delegate.refreshCount, 0)
        }
    }

    func testRefreshIfNeededOutsideGraceInterval() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 3500))
            let expect = expectation(description: "refresh")
            credential.refreshIfNeeded(graceInterval: 300) { result in
                switch result {
                case .success(let newToken):
                    XCTAssertNotNil(newToken)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expect.fulfill()
            }

            await fulfillment(of: [expect], timeout: 3.0)

            XCTAssertEqual(delegate.refreshCount, 1)
            XCTAssertFalse(credential.token.isRefreshing)
        }
    }
    
    func testAutomaticRefresh() async throws {
        try await taskData {
            Credential.refreshGraceInterval = 0.5
            let credential = try await credential(for: Token.mockToken(expiresIn: 1),
                                                  expectAPICalls: .refresh(count: 2),
                                                  expiresIn: 1)
            let urlSession = try XCTUnwrap(credential.oauth2.session as? URLSessionMock)

            XCTAssertEqual(urlSession.requests.count, 0)

            // Setting automatic refresh should refresh
            var refreshExpectation = expectation(description: "First refresh")
            delegate.refreshExpectation = refreshExpectation
            credential.automaticRefresh = true

            await fulfillment(of: [refreshExpectation], timeout: 1.0)
            XCTAssertEqual(urlSession.requests.count, 2)

            // Should automatically refresh after a delay
            urlSession.resetRequests()
            refreshExpectation = expectation(description: "Second refresh")
            delegate.refreshExpectation = refreshExpectation
            await fulfillment(of: [refreshExpectation], timeout: 3)

            XCTAssertEqual(urlSession.requests.count, 1)
            urlSession.resetRequests()

            // Stopping should prevent subsequent refreshes
            credential.automaticRefresh = false

            sleep(1)
            XCTAssertEqual(urlSession.requests.count, 0)
        }
    }
    
    func testAuthorizedURLSession() async throws {
        try await taskData {
            let credential = try await credential(for: Token.simpleMockToken)

            var request = URLRequest(url: URL(string: "https://example.com/my/api")!)
            credential.authorize(request: &request)

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"),
                           "Bearer \(credential.token.accessToken)")
        }
    }
    
    func testRotatingRefreshTokens() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(expiresIn: 1),
                                                  expectAPICalls: .refresh(count: 3, rotate: true),
                                                  expiresIn: 1)

            // Initial refresh token
            XCTAssertEqual(credential.token.refreshToken, "abc123")

            // First refresh
            let refreshExpectation1 = expectation(description: "First refresh")
            credential.refresh { _ in
                refreshExpectation1.fulfill()
            }
            await fulfillment(of: [refreshExpectation1], timeout: .standard)
            XCTAssertEqual(credential.token.refreshToken, "therefreshtoken-1")

            // Second refresh
            let refreshExpectation2 = expectation(description: "Second refresh")
            credential.refresh { _ in
                refreshExpectation2.fulfill()
            }
            await fulfillment(of: [refreshExpectation2], timeout: .standard)
            XCTAssertEqual(credential.token.refreshToken, "therefreshtoken-2")

            // Third refresh
            let refreshExpectation3 = expectation(description: "Third refresh")
            credential.refresh { _ in
                refreshExpectation3.fulfill()
            }
            await fulfillment(of: [refreshExpectation3], timeout: .standard)
            XCTAssertEqual(credential.token.refreshToken, "therefreshtoken-3")
        }
    }

    func testRefreshAsync() async throws {
        try await taskData {
            let credential = try await credential(for: Token.simpleMockToken)
            try perform {
                try await credential.refresh()
            }
        }
    }

    func testRefreshIfNeededExpiredAsync() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 6000))
            try perform {
                try await credential.refreshIfNeeded(graceInterval: 300)
            }
        }
    }

    func testRefreshIfNeededWithinGraceIntervalAsync() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 0),
                                                  expectAPICalls: .none)
            try perform {
                try await credential.refreshIfNeeded(graceInterval: 300)
            }
        }
    }

    func testRefreshIfNeededOutsideGraceIntervalAsync() async throws {
        try await taskData {
            let credential = try await credential(for: Token.mockToken(issuedOffset: 3500))
            try perform {
                try await credential.refreshIfNeeded(graceInterval: 300)
            }
        }
    }
}
