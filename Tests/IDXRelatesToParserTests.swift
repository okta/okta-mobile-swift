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

class IDXRelatesToParserTests: XCTestCase {
    typealias RelatesTo = IDXClient.APIVersion1.Response.RelatesTo
    struct Object: Decodable {
        let relatesTo: RelatesTo
    }
    
    func testEnum() throws {
        XCTAssertEqual(RelatesTo.Path(string: "$"), .root)
        XCTAssertEqual(RelatesTo.Path(string: "authenticatorEnrollments"), .property(name: "authenticatorEnrollments"))
        XCTAssertEqual(RelatesTo.Path(string: "5"), .array(index: 5))
    }
    
    func testSimplePath() throws {
        let string = """
        {"relatesTo":"$.authenticator.value[0]"}
        """
        let value = try JSONDecoder().decode(Object.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(value.relatesTo.path.count, 4)
        XCTAssertEqual(value.relatesTo.path[0], .root)
        XCTAssertEqual(value.relatesTo.path[1], .property(name: "authenticator"))
        XCTAssertEqual(value.relatesTo.path[2], .property(name: "value"))
        XCTAssertEqual(value.relatesTo.path[3], .array(index: 0))
    }
}
