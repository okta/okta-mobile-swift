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

final class DeviceInformationTests: XCTestCase {
    func testDescription() async throws {
        XCTAssertEqual(DeviceInformation(architecture: "arm64",
                                         kernelName: "Darwin",
                                         deviceModel: "iPhone15,2",
                                         platform: "iOS",
                                         version: "18.0.1").description,
                       "Language/Swift (iOS/18.0.1; iPhone15,2) Kernel/Darwin (arm64)")
        XCTAssertEqual(DeviceInformation(architecture: nil,
                                         kernelName: "Darwin",
                                         deviceModel: "iPhone15,2",
                                         platform: "iOS",
                                         version: "18.0.1").description,
                       "Language/Swift (iOS/18.0.1; iPhone15,2) Kernel/Darwin")
        XCTAssertEqual(DeviceInformation(architecture: "arm64",
                                         kernelName: nil,
                                         deviceModel: "iPhone15,2",
                                         platform: "iOS",
                                         version: "18.0.1").description,
                       "Language/Swift (iOS/18.0.1; iPhone15,2) Kernel (arm64)")
        XCTAssertEqual(DeviceInformation(architecture: "arm64",
                                         kernelName: "Darwin",
                                         deviceModel: nil,
                                         platform: "iOS",
                                         version: "18.0.1").description,
                       "Language/Swift (iOS/18.0.1) Kernel/Darwin (arm64)")
    }

    func testEqualityAndCodable() async throws {
        let info = DeviceInformation(architecture: "arm64",
                                     kernelName: "Darwin",
                                     deviceModel: "iPhone15,2",
                                     platform: "iOS",
                                     version: "18.0.1")
        let data = try JSONEncoder().encode(info)
        let copy = try JSONDecoder().decode(DeviceInformation.self, from: data)
        XCTAssertEqual(info, copy)
    }
}
