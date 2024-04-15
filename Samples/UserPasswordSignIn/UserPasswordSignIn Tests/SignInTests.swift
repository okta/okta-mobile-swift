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

class SignInTests: XCTestCase {
    var commandPath: URL?
    
    lazy var domain: String? = {
        ProcessInfo.processInfo.environment["E2E_DOMAIN"]
    }()
    
    lazy var clientId: String? = {
        ProcessInfo.processInfo.environment["E2E_CLIENT_ID"]
    }()
    
    lazy var scopes: String? = {
        ProcessInfo.processInfo.environment["E2E_SCOPES"]
    }()
    
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()
    
    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()

    override func setUpWithError() throws {
        let bundlePath = try XCTUnwrap(ProcessInfo.processInfo.environment["XCTestBundlePath"])
        let bundleFileURL = try XCTUnwrap(URL(fileURLWithPath: bundlePath))
        commandPath = bundleFileURL.deletingLastPathComponent().appendingPathComponent("UserPasswordSignIn")
    }

    func testSignIn() throws {
        let commandPath = try XCTUnwrap(commandPath)
        let domain = try XCTUnwrap(domain)
        let clientId = try XCTUnwrap(clientId)
        let scopes = try XCTUnwrap(scopes)
        let username = try XCTUnwrap(username)
        let password = try XCTUnwrap(password)

        let command = Command(commandPath, arguments: [
            "--issuer", "https://\(domain)/oauth2/default",
            "--client-id", clientId,
            "--scopes", scopes,
            "--username", username,
            "--password", password,
        ])
        
        try command.run()
        
        XCTAssertEqual(command.output?["Username"], username)
        XCTAssertNotNil(command.output?["User ID"])
    }
}
