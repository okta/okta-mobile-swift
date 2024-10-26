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
@testable import AuthFoundationTestCommon

final class CredentialDataSourceDelegateRecorder: CredentialDataSourceDelegate {
    nonisolated(unsafe) private(set) var created: [Credential] = []
    nonisolated(unsafe) private(set) var removed: [Credential] = []
    nonisolated(unsafe) private(set) var callCount = 0

    func credential(dataSource: CredentialDataSource, created credential: Credential) {
        created.append(credential)
        callCount += 1
    }
    
    func credential(dataSource: CredentialDataSource, removed credential: Credential) {
        removed.append(credential)
        callCount += 1
    }
    
    func reset() {
        created.removeAll()
        removed.removeAll()
        callCount = 0
    }
}

final class DefaultCredentialDataSourceTests: XCTestCase {
    var coordinator: MockCredentialCoordinator!
    var dataSource: DefaultCredentialDataSource!
    var delegate: CredentialDataSourceDelegateRecorder!

    let configuration = OAuth2Client.Configuration(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scopes: "openid")
    

    override func setUpWithError() throws {
        coordinator = MockCredentialCoordinator()
        delegate = CredentialDataSourceDelegateRecorder()
        dataSource = DefaultCredentialDataSource()
        dataSource.delegate = delegate
        coordinator.credentialDataSource = dataSource
    }
    
    override func tearDownWithError() throws {
        coordinator = nil
        delegate = nil
        dataSource = nil
    }
    
    func testCredentials() throws {
        XCTAssertEqual(dataSource.credentialCount, 0)
        
        let token = try! Token(id: "TokenId",
                               issuedAt: Date(),
                               tokenType: "Bearer",
                               expiresIn: 300,
                               accessToken: "abcd123",
                               scope: "openid",
                               refreshToken: nil,
                               idToken: nil,
                               deviceSecret: nil,
                               context: Token.Context(configuration: configuration,
                                                      clientSettings: nil))
        
        XCTAssertFalse(dataSource.hasCredential(for: token))
        
        let credential = dataSource.credential(for: token, coordinator: coordinator)
        XCTAssertEqual(credential.token, token)
        XCTAssertEqual(dataSource.credentialCount, 1)
        XCTAssertTrue(dataSource.hasCredential(for: token))
        XCTAssertTrue(delegate.created.contains(credential))
        XCTAssertEqual(delegate.callCount, 1)

        let user2 = dataSource.credential(for: token, coordinator: coordinator)
        XCTAssertEqual(credential.token, token)
        XCTAssertTrue(credential === user2)
        XCTAssertEqual(dataSource.credentialCount, 1)
        XCTAssertEqual(delegate.callCount, 1)

        dataSource.remove(credential: credential)
        XCTAssertEqual(dataSource.credentialCount, 0)
        XCTAssertFalse(dataSource.hasCredential(for: token))
        XCTAssertTrue(delegate.removed.contains(credential))
        XCTAssertEqual(delegate.callCount, 2)
        
        let user3 = dataSource.credential(for: token, coordinator: coordinator)
        XCTAssertEqual(credential.token, token)
        XCTAssertFalse(credential === user3)
    }
}
