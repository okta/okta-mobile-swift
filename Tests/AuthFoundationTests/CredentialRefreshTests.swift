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

#if os(Android)
import Android
#endif

class CredentialRefreshDelegate: OAuth2ClientDelegate, @unchecked Sendable {
    private(set) var refreshCount = 0
    
    func reset() {
        refreshCount = 0
        refreshContinuation = nil
    }
    
    var refreshContinuation: (CheckedContinuation<Token?, any Error>)?
    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        refreshCount += 1
        
        if let refreshContinuation {
            refreshContinuation.resume(returning: newToken)
            self.refreshContinuation = nil
        }
    }
}

@Suite("Credential refresh tests", .serialized, .credentialCoordinator)
final class CredentialRefreshTests: OAuth2ClientDelegate, @unchecked Sendable {
    enum APICalls {
        case none
        case error(ErrorResponse = .noResponse)
        case openIdOnly
        case refresh(count: Int, rotate: Bool = false)
        
        enum ErrorResponse {
            case noResponse
            case invalidRequest
            
            var statusCode: Int {
                switch self {
                case .noResponse: return 500
                case .invalidRequest: return 400
                }
            }
            var data: Data? {
                switch self {
                case .noResponse: return nil
                case .invalidRequest:
                    return """
                        {"error": "invalid_request"}
                    """.data(using: .utf8)
                }
            }
        }
    }

    func credential(for token: Token,
                    delegate: CredentialRefreshDelegate? = nil,
                    expectAPICalls: APICalls = .refresh(count: 1),
                    expiresIn: TimeInterval = 3600) async throws -> Credential
    {
        let credential = try await Credential.providers.coordinator.store(token: token, tags: [:], security: Credential.Security.standard)
        if let delegate {
            credential.oauth2.add(delegate: delegate)
        }
        
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
            
        case .error(let errorType):
            urlSession.expect("https://example.com/.well-known/openid-configuration",
                              data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                              contentType: "application/json")
            urlSession.expect("https://example.com/oauth2/v1/token",
                              data: errorType.data,
                              statusCode: errorType.statusCode)
        }
        
        return credential
    }

    @Test("Successful refresh with delegate and notifications", .notificationCenter)
    func testRefresh() async throws {
        let notificationCenter = try #require(Test.current?.notificationCenter)
        let notification = NotificationRecorder(center: notificationCenter,
                                                observing: [.tokenRefreshed])

        let delegate = CredentialRefreshDelegate()
        let credential = try await credential(for: Token.simpleMockToken,
                                              delegate: delegate,
                                              expectAPICalls: .refresh(count: 1,
                                                                       rotate: false))

        #expect(credential.token.refreshToken == "abc123")

        try await confirmClosure("Perform refresh") { confirm in
            credential.refresh { confirm($0) }
        }
        
        #expect(!credential.token.isRefreshing)
        #expect(credential.token.refreshToken == "therefreshtoken")
        
        await MainActor.yield()

        #expect(notification.notifications.count == 1)
        let tokenNotification = try #require(notification.notifications(for: .tokenRefreshed).first)
        #expect(tokenNotification.object as? Token == credential.token)
        #expect(tokenNotification.userInfo?["error"] == nil)

        #expect(delegate.refreshCount == 1)
    }

    @Test("Notifications sent upon refresh failure", .notificationCenter)
    func testRefreshFailed() async throws {
        let notificationCenter = try #require(Test.current?.notificationCenter)
        let notification = NotificationRecorder(center: notificationCenter,
                                                observing: [.credentialRefreshFailed, .tokenRefreshFailed])
        let credential = try await credential(for: Token.simpleMockToken, expectAPICalls: .error(.invalidRequest))
        let error = await #expect(throws: OAuth2Error.self) {
            try await confirmClosure("Perform refresh") { confirm in
                credential.refresh { confirm($0) }
            }
        }
        
        #expect(error == .server(error: .init(code: "invalid_request", description: nil)))

        await MainActor.yield()
        
        #expect(notification.notifications.count == 2)
        let tokenNotification = try #require(notification.notifications(for: .tokenRefreshFailed).first)
        #expect(tokenNotification.object as? Token == credential.token)
        #expect(tokenNotification.userInfo?["error"] != nil)
        
        let credentialNotification = try #require(notification.notifications(for: .credentialRefreshFailed).first)
        #expect(credentialNotification.object as? Credential == credential)
        #expect(credentialNotification.userInfo?["error"] != nil)
    }

    @Test("Refresh fails without a refresh token", .notificationCenter)
    func testRefreshWithoutRefreshToken() async throws {
        let credential = try await credential(for: Token.mockToken(id: "TokenID",
                                                                   refreshToken: nil))

        let error = await #expect(throws: OAuth2Error.self) {
            try await confirmClosure { confirm in
                credential.refresh { confirm($0) }
            }
        }
        
        #expect(error != nil)
        #expect(error == .missingToken(type: .refreshToken))
    }

    @Test("Ensure optional values are preserved after refresh")
    func testRefreshWithoutOptionalValues() async throws {
        let credential = try await credential(for: Token.mockToken(id: "TokenID",
                                                                   refreshToken: "originalRefreshToken",
                                                                   deviceSecret: "theDeviceSecret"),
                                              expectAPICalls: .refresh(count: 1, rotate: true))

        #expect(credential.token.deviceSecret == "theDeviceSecret")
        #expect(credential.token.refreshToken == "originalRefreshToken")

        try await confirmClosure { confirm in
            credential.refresh { confirm($0) }
        }
        
        #expect(credential.token.deviceSecret == "theDeviceSecret")
        #expect(credential.token.refreshToken == "therefreshtoken-1")
    }
    
    @Test("Refresh if needed when token is expired")
    func testRefreshIfNeededExpired() async throws {
        let delegate = CredentialRefreshDelegate()
        let credential = try await credential(for: Token.mockToken(issuedOffset: 6000),
                                              delegate: delegate)
        
        #expect(credential.token.refreshToken == "abc123")
        
        try await confirmClosure("Perform refresh if needed") { confirm in
            credential.refreshIfNeeded(graceInterval: 300) { confirm($0) }
        }
        
        #expect(!credential.token.isRefreshing)
        #expect(credential.token.refreshToken == "therefreshtoken")
        #expect(delegate.refreshCount == 1)
    }

    @Test("Refresh if needed within grace interval")
    func testRefreshIfNeededWithinGraceInterval() async throws {
        let delegate = CredentialRefreshDelegate()
        let credential = try await credential(for: Token.mockToken(issuedOffset: 0),
                                              delegate: delegate,
                                              expectAPICalls: .none)
        
        #expect(!credential.token.isRefreshing)
        #expect(credential.token.refreshToken == "abc123")
        
        try await confirmClosure("Perform refresh if needed") { confirm in
            credential.refreshIfNeeded(graceInterval: 300) { confirm($0) }
        }
        
        #expect(credential.token.refreshToken == "abc123")
        #expect(!credential.token.isRefreshing)
        #expect(delegate.refreshCount == 0)
    }
    
    @Test("Refresh if needed outside grace interval")
    func testRefreshIfNeededOutsideGraceInterval() async throws {
        let delegate = CredentialRefreshDelegate()
        let credential = try await credential(for: Token.mockToken(issuedOffset: 3500),
                                              delegate: delegate)
        
        #expect(credential.token.refreshToken == "abc123")

        try await confirmClosure("Perform refresh if needed") { confirm in
            credential.refreshIfNeeded(graceInterval: 300) { confirm($0) }
        }
        
        #expect(credential.token.refreshToken == "therefreshtoken")
        #expect(delegate.refreshCount == 1)
        #expect(!credential.token.isRefreshing)
    }
    
    // TODO: This test should be refactored to not rely on wallclock timing, which can become flaky within CI environments.
    @Test("Automatic token refresh", .notificationCenter)
    func testAutomaticRefresh() async throws {
        Credential.refreshGraceInterval = 0.5
        let delegate = CredentialRefreshDelegate()
        let credential = try await credential(for: Token.mockToken(expiresIn: 1),
                                              delegate: delegate,
                                              expectAPICalls: .refresh(count: 2),
                                              expiresIn: 1)
        let urlSession = try #require(credential.oauth2.session as? URLSessionMock)

        #expect(urlSession.requests.count == 0)

        let token: Token? = try await withCheckedThrowingContinuation { continuation in
            delegate.refreshContinuation = continuation
            credential.automaticRefresh = true
        }

        // Stopping should prevent subsequent refreshes
        credential.automaticRefresh = false

        #expect(urlSession.requests(matching: .url("/token")).count == 1)
        urlSession.resetRequests()
        
        #expect(token == credential.token)
    }
    
    @Test("Authorized URL session functionality")
    func testAuthorizedURLSession() async throws {
        let credential = try await credential(for: Token.simpleMockToken)

        var request = URLRequest(url: URL(string: "https://example.com/my/api")!)
        credential.authorize(request: &request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(credential.token.accessToken)")
    }
    
    @Test("Rotating refresh tokens functionality")
    func testRotatingRefreshTokens() async throws {
        let credential = try await credential(for: Token.mockToken(expiresIn: 1),
                                              expectAPICalls: .refresh(count: 3, rotate: true),
                                              expiresIn: 1)

        // Initial refresh token
        #expect(credential.token.refreshToken == "abc123")

        // First refresh
        try await confirmClosure("First refresh") { confirm in
            credential.refresh { confirm($0) }
        }
        #expect(credential.token.refreshToken == "therefreshtoken-1")

        // Second refresh
        try await confirmClosure("Second refresh") { confirm in
            credential.refresh { confirm($0) }
        }
        #expect(credential.token.refreshToken == "therefreshtoken-2")

        // Third refresh
        try await confirmClosure("Third refresh") { confirm in
            credential.refresh { confirm($0) }
        }
        #expect(credential.token.refreshToken == "therefreshtoken-3")
    }
    
    func testRefreshAsync() async throws {
        let credential = try await credential(for: Token.simpleMockToken)
        try await performConcurrent {
            try await credential.refresh()
        }
    }

    func testRefreshIfNeededExpiredAsync() async throws {
        let credential = try await credential(for: Token.mockToken(issuedOffset: 6000))
        try await performConcurrent {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }
    
    func testRefreshIfNeededWithinGraceIntervalAsync() async throws {
        let credential = try await credential(for: Token.mockToken(issuedOffset: 0),
                                              expectAPICalls: .none)
        try await performConcurrent {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }
    
    func testRefreshIfNeededOutsideGraceIntervalAsync() async throws {
        let credential = try await credential(for: Token.mockToken(issuedOffset: 3500))
        try await performConcurrent {
            try await credential.refreshIfNeeded(graceInterval: 300)
        }
    }
}
