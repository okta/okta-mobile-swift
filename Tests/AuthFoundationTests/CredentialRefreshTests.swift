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

class CredentialRefreshDelegate: OAuth2ClientDelegate {
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

final class CredentialRefreshTests: XCTestCase, OAuth2ClientDelegate {
    var delegate: CredentialRefreshDelegate!
    var coordinator: MockCredentialCoordinator!
    var notification: NotificationRecorder!

    enum APICalls {
        case none
        case error
        case openIdOnly
        case refresh(count: Int)
    }

    func credential(for token: Token, expectAPICalls: APICalls = .refresh(count: 1), expiresIn: TimeInterval = 3600) throws -> Credential {
        let credential = coordinator.credentialDataSource.credential(for: token, coordinator: coordinator)
        credential.oauth2.add(delegate: delegate)
        
        let urlSession = credential.oauth2.session as! URLSessionMock
        urlSession.resetRequests()
        
        switch expectAPICalls {
        case .none: break
        case .openIdOnly:
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")

        case .refresh(let count):
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            for _ in 1 ... count {
                urlSession.expect("https://example.com/oauth2/v1/token",
                                  data: data(for: """
                {
                   "token_type": "Bearer",
                   "expires_in": \(expiresIn),
                   "access_token": "\(String.mockAccessToken)",
                   "scope": "openid profile offline_access",
                   "refresh_token": "therefreshtoken",
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
    
    override func setUpWithError() throws {
        delegate = CredentialRefreshDelegate()
        coordinator = MockCredentialCoordinator()
        notification = NotificationRecorder(observing: [.credentialRefreshFailed, .tokenRefreshFailed])
    }
    
    override func tearDownWithError() throws {
        delegate = nil
        coordinator = nil
        notification = nil
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

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
        XCTAssertEqual(delegate.refreshCount, 1)
    }

    func testRefreshFailed() throws {
        let credential = try credential(for: Token.simpleMockToken, expectAPICalls: .error)

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
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
        
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
    
    func testRefreshWithoutRefreshToken() throws {
        let credential = try credential(for: Token.mockToken(id: "TokenID",
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
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }

    func testRefreshWithoutOptionalValues() throws {
        let credential = try credential(for: Token.mockToken(id: "TokenID",
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
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(credential.token.deviceSecret, "theDeviceSecret")
    }

    func testRefreshIfNeededExpired() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 6000))
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
        
        XCTAssertTrue(credential.token.isRefreshing)

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
        XCTAssertEqual(delegate.refreshCount, 1)
}

    func testRefreshIfNeededWithinGraceInterval() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 0),
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

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertFalse(credential.token.isRefreshing)
        XCTAssertEqual(delegate.refreshCount, 0)
    }

    func testRefreshIfNeededOutsideGraceInterval() throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 3500))
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
        
        XCTAssertTrue(credential.token.isRefreshing)
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertEqual(delegate.refreshCount, 1)
        XCTAssertFalse(credential.token.isRefreshing)
    }
    
    func testAutomaticRefresh() throws {
        Credential.refreshGraceInterval = 0.5
        let credential = try credential(for: Token.mockToken(expiresIn: 1), expectAPICalls: .refresh(count: 2), expiresIn: 1)
        let urlSession = try XCTUnwrap(credential.oauth2.session as? URLSessionMock)

        XCTAssertEqual(urlSession.requests.count, 0)

        // Setting automatic refresh should refresh
        var refreshExpectation = expectation(description: "First refresh")
        delegate.refreshExpectation = refreshExpectation
        credential.automaticRefresh = true
        
        wait(for: [refreshExpectation], timeout: 1.0)
        XCTAssertEqual(urlSession.requests.count, 2)
        
        // Should automatically refresh after a delay
        urlSession.resetRequests()
        refreshExpectation = expectation(description: "Second refresh")
        delegate.refreshExpectation = refreshExpectation
        wait(for: [refreshExpectation], timeout: 3)

        XCTAssertEqual(urlSession.requests.count, 1)
        urlSession.resetRequests()

        // Stopping should prevent subsequent refreshes
        credential.automaticRefresh = false
        
        sleep(1)
        XCTAssertEqual(urlSession.requests.count, 0)
    }
    
    func testAuthorizedURLSession() throws {
        let credential = try credential(for: Token.simpleMockToken)
        
        var request = URLRequest(url: URL(string: "https://example.com/my/api")!)
        credential.authorize(request: &request)
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"),
                       "Bearer \(credential.token.accessToken)")
    }

    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRefreshAsync() async throws {
        let credential = try credential(for: Token.simpleMockToken)
        try perform {
            try await credential.refresh()
        }
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRefreshIfNeededExpiredAsync() async throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 6000))
        try perform {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRefreshIfNeededWithinGraceIntervalAsync() async throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 0),
                                           expectAPICalls: .none)
        try perform {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testRefreshIfNeededOutsideGraceIntervalAsync() async throws {
        let credential = try credential(for: Token.mockToken(issuedOffset: 3500))
        try perform {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }
    #endif
}
