//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaIdxAuth

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class RelyingPartyIdentifierTests: XCTestCase {
    func testExplicitRegistrationIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "https://issuer.example.com"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name",
                "id": "root.example.com"
              }
            }
            """))

        XCTAssertEqual(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL),
                       "root.example.com")
    }

    func testExplicitAuthenticationIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "https://issuer.example.com"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name"
              },
              "rpId": "rpId.example.com"
            }
            """))

        XCTAssertEqual(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL),
                       "rpId.example.com")
    }

    func testInferredFromU2FParamsIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "https://issuer.example.com"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name"
              },
              "u2fParams": {
                "appid": "https://u2f.example.com"
              }
            }
            """))

        XCTAssertEqual(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL),
                       "u2f.example.com")
    }

    func testInferredFromExtensionsIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "https://issuer.example.com"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name"
              },
              "extensions": {
                "appid": "https://ext.example.com"
              }
            }
            """))

        XCTAssertEqual(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL),
                       "ext.example.com")
    }

    func testInferredFromIssuerIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "https://issuer.example.com"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name"
              }
            }
            """))

        XCTAssertEqual(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL),
                       "issuer.example.com")
    }

    func testInvalidIssuerUrlIdentifier() throws {
        let issuerURL = try XCTUnwrap(URL(string: "com.example:/"))
        let json = try JSONDecoder().decode(JSON.self, from: data(for: """
            {
              "rp": {
                "name": "example-org-name"
              }
            }
            """))

        XCTAssertThrowsError(try String.relyingPartyIssuer(from: json, issuerURL: issuerURL))
    }
}
