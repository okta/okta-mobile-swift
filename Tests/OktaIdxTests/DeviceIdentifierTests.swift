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
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

final class DeviceIdentifierTests: XCTestCase {
    #if canImport(UIKit) && (os(iOS) || os(macOS) || os(tvOS))
    func testSystemDeviceIdentifier() throws {
        XCTAssertEqual(InteractionCodeFlow.systemDeviceIdentifier, UIDevice.current.identifierForVendor)
    }
    #elseif canImport(WatchKit)
    func testSystemDeviceIdentifier() throws {
        XCTAssertEqual(InteractionCodeFlow.systemDeviceIdentifier, WKInterfaceDevice.current().identifierForVendor)
    }
    #endif
    
    #if canImport(UIKit) && (os(iOS) || os(macOS) || os(tvOS) || canImport(WatchKit))
    func testDeviceIdentifier() throws {
        let urlSession = URLSessionMock()
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        let client = OAuth2Client(baseURL: issuer,
                                  clientId: "clientId",
                                  scopes: "openid profile",
                                  session: urlSession)
        let flow = InteractionCodeFlow(redirectUri: redirectUri, client: client)
        let identifier = try XCTUnwrap(flow.deviceIdentifierString)
        
        // Device Token string _must_ be 32 characters or less.
        XCTAssertLessThanOrEqual(identifier.count, 32)
        
        let data = try XCTUnwrap(Data(base64Encoded: identifier, options: .ignoreUnknownCharacters))
        
        var nsuuid: NSUUID?
        data.withUnsafeBytes { (unsafeBytes) in
            let bytes = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
            nsuuid = NSUUID(uuidBytes: bytes)
        }

        let uuidString = try XCTUnwrap(nsuuid?.uuidString)
        let uuid = try XCTUnwrap(UUID(uuidString: uuidString))

        XCTAssertEqual(uuid, InteractionCodeFlow.systemDeviceIdentifier)
    }
    #endif
}
