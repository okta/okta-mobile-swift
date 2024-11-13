//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaUtilities

final class UserAgentTests: XCTestCase {
    func testDescription() async throws {
        let userAgent = UserAgent(device: .init(architecture: nil,
                                                kernelName: nil,
                                                deviceModel: nil,
                                                platform: .other,
                                                version: "1.0.0"))

        XCTAssertEqual(userAgent.description, "Language/Swift (Other/1.0.0)")

        userAgent.client = .init("MyApp", identifier: "com.my.app", version: "1.0")
        XCTAssertEqual(userAgent.description, "Language/Swift (Other/1.0.0) MyApp/1.0 (com.my.app)")
        
        userAgent.client = .init("MyApp", version: "1.0")
        XCTAssertEqual(userAgent.description, "Language/Swift (Other/1.0.0) MyApp/1.0")
        
        userAgent.register(target: .init("SecondSDK", version: "1.2.3"))
        XCTAssertEqual(userAgent.description, "Language/Swift (Other/1.0.0) MyApp/1.0 SecondSDK/1.2.3")

        userAgent.register(target: .init("FirstSDK", version: "3.0.1"))
        XCTAssertEqual(userAgent.description, "Language/Swift (Other/1.0.0) MyApp/1.0 FirstSDK/3.0.1 SecondSDK/1.2.3")
    }
}
