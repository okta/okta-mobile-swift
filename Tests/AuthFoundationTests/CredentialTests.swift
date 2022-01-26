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
    let coordinator = MockCredentialCoordinator()
    var credential: Credential!
    var urlSession: URLSessionMock!

    let token = Token(issuedAt: Date(),
                      tokenType: "Bearer",
                      expiresIn: 300,
                      accessToken: "abcd123",
                      scope: "openid",
                      refreshToken: nil,
                      idToken: nil,
                      deviceSecret: nil,
                      context: Token.Context(baseURL: URL(string: "https://example.com")!,
                                             clientSettings: [ "client_id": "foo" ]))

    override func setUpWithError() throws {
        credential = coordinator.credentialDataSource.credential(for: token, coordinator: coordinator)
        urlSession = credential.oauth2.session as? URLSessionMock
    }

    func testRemove() throws {
        XCTAssertNoThrow(try credential.remove())
        XCTAssertFalse(coordinator.credentialDataSource.hasCredential(for: token))
    }
    
    func testRevoke() throws {
        urlSession.expect("https://example.com/oauth2/default/v1/revoke",
                          data: Data())
        
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
    }
}