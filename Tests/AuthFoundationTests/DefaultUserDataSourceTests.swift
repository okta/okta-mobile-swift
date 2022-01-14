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

final class DefaultUserDataSourceTests: XCTestCase {
    var dataSource: DefaultUserDataSource!
    
    override func setUpWithError() throws {
        dataSource = DefaultUserDataSource()
    }
    
    func testUsers() throws {
        XCTAssertEqual(dataSource.userCount, 0)
        
        let token = Token(issuedAt: Date(),
                          tokenType: "Bearer",
                          expiresIn: 300,
                          accessToken: "abcd123",
                          scope: "openid",
                          refreshToken: nil,
                          idToken: nil,
                          deviceSecret: nil,
                          context: Token.Context(baseURL: URL(string: "https://example.com")!,
                                                 refreshSettings: nil))
        let user = dataSource.user(for: token)
        XCTAssertEqual(user.token, token)
        XCTAssertEqual(dataSource.userCount, 1)

        let user2 = dataSource.user(for: token)
        XCTAssertEqual(user.token, token)
        XCTAssertTrue(user === user2)
        XCTAssertEqual(dataSource.userCount, 1)
        
        dataSource.remove(user: user)
        XCTAssertEqual(dataSource.userCount, 0)
    }
}
