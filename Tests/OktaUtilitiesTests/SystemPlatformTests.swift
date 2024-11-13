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

final class SystemPlatformTests: XCTestCase {
    func testConstants() async throws {
        XCTAssertEqual(SystemPlatform.android, "Android")
        XCTAssertEqual(SystemPlatform.macOS, "macOS")
        XCTAssertEqual(SystemPlatform.macCatalyst, "macCatalyst")
        XCTAssertEqual(SystemPlatform.iOS, "iOS")
        XCTAssertEqual(SystemPlatform.tvOS, "tvOS")
        XCTAssertEqual(SystemPlatform.watchOS, "watchOS")
        XCTAssertEqual(SystemPlatform.visionOS, "visionOS")
        XCTAssertEqual(SystemPlatform.linux, "Linux")
        XCTAssertEqual(SystemPlatform.android, "Android")
        XCTAssertEqual(SystemPlatform.windows, "Windows")
        XCTAssertEqual(SystemPlatform.wasi, "WASI")
        XCTAssertEqual(SystemPlatform.openbsd, "OpenBSD")
        XCTAssertEqual(SystemPlatform.freebsd, "FreeBSD")
        XCTAssertEqual(SystemPlatform.other, "Other")
    }
}
