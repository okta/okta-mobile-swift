/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdx

class IDXClientVersionTests: XCTestCase {
    func testVersionEnum() throws {
        var value: IDXClient.Version? = nil
            
        value = .v1_0_0
        XCTAssertEqual(value?.rawValue, "1.0.0")
        
        value = IDXClient.Version(rawValue: "1.0.0")
        XCTAssertEqual(value, .v1_0_0)
        
        XCTAssertEqual(IDXClient.Version.latest,
                       .v1_0_0)
        
        let configuration = IDXClient.Configuration(issuer: "foo", clientId: "bar", clientSecret: "baz", scopes: ["boo"], redirectUri: "woo")
        let api = IDXClient.Version.v1_0_0.clientImplementation(with: configuration)
        XCTAssertTrue(type(of: api) == IDXClient.APIVersion1.self)
        
        XCTAssertNil(IDXClient.Version.init(rawValue: "invalid-version"))
    }
}
