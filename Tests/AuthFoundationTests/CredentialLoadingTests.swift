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

final class CredentialLoadingTests: XCTestCase {
    var userDefaults: UserDefaults!
    var storage: UserDefaultsTokenStorage!
    var coordinator: CredentialCoordinatorImpl!
    
    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        let storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        coordinator = CredentialCoordinatorImpl(tokenStorage: storage)
        
        XCTAssertEqual(storage.allIDs.count, 0)
        self.storage = storage
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: name)

        userDefaults = nil
        storage = nil
        coordinator = nil
    }
    
    func testFetchingTokens() throws {
        let tokenA = Token.mockToken(id: "TokenA", tags: ["animal": "cat"])
        let tokenB = Token.mockToken(id: "TokenB", tags: ["animal": "dog"])
        let tokenC = Token.mockToken(id: "TokenC", tags: ["animal": "pig"])
        let tokenD = Token.mockToken(id: "TokenD", tags: ["animal": "emu"])

        try storage.add(token: tokenA, security: [])
        try storage.add(token: tokenB, security: [])
        try storage.add(token: tokenC, security: [])
        try storage.add(token: tokenD, security: [])
        
        XCTAssertEqual(try coordinator.with(id: "TokenA", prompt: nil, authenticationContext: nil)?.token, tokenA)
        XCTAssertEqual(try coordinator.find(where: { meta in
            meta.tags["animal"] == "cat"
        }).count, 1)
        XCTAssertEqual(try coordinator.find(where: { meta in
            meta.tags["animal"] == "cat"
        }).first?.token, tokenA)
        XCTAssertEqual(try coordinator.find(where: { meta in
            meta.tags.keys.contains("animal")
        }).count, 4)
        XCTAssertEqual(try coordinator.find(where: { meta in
            meta[.name] == "Arthur Dent"
        }).count, 4)
    }
}
