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

#if os(Linux)
import FoundationNetworking
#endif

@testable import TestCommon
@testable import AuthFoundation

final class UserCoordinatorTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    var coordinator: CredentialCoordinatorImpl!
    
    let token = Token(issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(baseURL: URL(string: "https://example.com")!,
                                             clientSettings: nil))

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        
        coordinator = CredentialCoordinatorImpl(tokenStorage: storage)
        
        XCTAssertEqual(storage.allTokens.count, 0)
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: #file)
    }
    
    func testDefaultCredentialViaToken() throws {
        storage.defaultToken = token

        XCTAssertEqual(storage.allTokens.count, 1)
        
        let credential = try XCTUnwrap(coordinator.default)
        XCTAssertEqual(credential.token, token)
        
        coordinator.default = nil
        XCTAssertNil(coordinator.default)
        XCTAssertNil(storage.defaultToken)
        XCTAssertEqual(storage.allTokens.count, 1)
        
        XCTAssertEqual(coordinator.allCredentials, [credential])
        XCTAssertEqual(coordinator.for(token: token), credential)
        XCTAssertTrue(coordinator.for(token: token) === credential)
    }
    
    func testImplicitCredentialForToken() throws {
        let credential = coordinator.for(token: token)
        
        XCTAssertEqual(storage.allTokens.count, 1)
        XCTAssertEqual(coordinator.default, credential)
    }
    
    func testNotifications() throws {
        let recorder = NotificationRecorder(observing: [.defaultCredentialChanged])
        
        let credential = coordinator.for(token: token)
        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertEqual(recorder.notifications.first?.object as? Credential, credential)
        
        recorder.reset()
        coordinator.default = nil
        XCTAssertEqual(recorder.notifications.count, 1)
        XCTAssertNil(recorder.notifications.first?.object)
    }
    
    // TODO: Figure a better solution to this automatic token injection.
    func disabled_testAutomaticTokenImport() throws {
        XCTAssertEqual(storage.allTokens.count, 0)
        
        let issuer = URL(string: "https://example.com")!
        let urlSession = URLSessionMock()
        let client = OAuth2Client(baseURL: issuer, session: urlSession)
        
        let request = URLRequest(url: URL(string: "https://example.com/oauth2/default/v1/token")!)
        let response: APIResponse<Token> = APIResponse(result: token,
                                                       date: Date(),
                                                       links: [:],
                                                       rateInfo: nil,
                                                       requestId: nil)
        client.delegateCollection.invoke { delegate in
            delegate.api(client: client, didSend: request, received: response)
        }
        
        XCTAssertEqual(storage.allTokens.count, 1)
        XCTAssertEqual(storage.defaultToken, token)
    }
}
