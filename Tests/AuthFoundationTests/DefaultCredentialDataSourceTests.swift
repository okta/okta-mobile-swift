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

class CredentialDataSourceDelegateRecorder: CredentialDataSourceDelegate {
    private(set) var created: [Credential] = []
    private(set) var removed: [Credential] = []
    private(set) var callCount = 0

    // Explicitly mark init() as nonisolated since Swift 5.10 is not able
    // to properly infer this behavior when a non-actor type conforms to
    // a global-actor protocol.
    nonisolated init() {}

    func credential(dataSource: any CredentialDataSource, created credential: Credential) {
        created.append(credential)
        callCount += 1
    }
    
    func credential(dataSource: any CredentialDataSource, removed credential: Credential) {
        removed.append(credential)
        callCount += 1
    }
    
    func reset() {
        created.removeAll()
        removed.removeAll()
        callCount = 0
    }
}

@Suite("Default credential data source")
struct DefaultCredentialDataSourceTests {
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")

    @CredentialActor
    final class StorageContext {
        let coordinator: MockCredentialCoordinator
        let dataSource: DefaultCredentialDataSource

        init(delegate: any CredentialDataSourceDelegate) {
            coordinator = MockCredentialCoordinator()
            dataSource = DefaultCredentialDataSource()
            
            coordinator.credentialDataSource = dataSource
            dataSource.delegate = delegate
        }
    }

    @Test("Add and remove credentials")
    @CredentialActor
    func testCredentials() async throws {
        let delegate = CredentialDataSourceDelegateRecorder()
        let context = StorageContext(delegate: delegate)
        let dataSource = context.dataSource
        let coordinator = context.coordinator

        #expect(dataSource.credentialCount == 0)
        
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
        
        #expect(!dataSource.hasCredential(for: token))
        
        let credential = dataSource.credential(for: token, coordinator: coordinator)
        #expect(credential.token == token)
        #expect(dataSource.credentialCount == 1)
        #expect(dataSource.hasCredential(for: token))
        #expect(delegate.created.contains(credential))
        #expect(delegate.callCount == 1)

        let user2 = dataSource.credential(for: token, coordinator: coordinator)
        #expect(credential.token == token)
        #expect(credential === user2)
        #expect(dataSource.credentialCount == 1)
        #expect(delegate.callCount == 1)

        dataSource.remove(credential: credential)
        #expect(dataSource.credentialCount == 0)
        #expect(!dataSource.hasCredential(for: token))
        #expect(delegate.removed.contains(credential))
        #expect(delegate.callCount == 2)
        
        let user3 = dataSource.credential(for: token, coordinator: coordinator)
        #expect(credential.token == token)
        #expect(credential !== user3)
    }
}
