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
@testable import AuthFoundation
import TestCommon

final class JWTTests: XCTestCase {
    let accessToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJ2ZXIiOjEsImp0aSI6IkFULko2amxNY1p5TnkxVmk2cnprTEIwbHEyYzBsSHFFSjhwSGN0NHV6aWxhazAub2FyOWVhenlMakFtNm13Wkc0dzQiLCJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTY0MjUzMjU2MiwiZXhwIjoxNjQyNTM2MTYyLCJjaWQiOiIwb2EzZW40ZkFBQTNkZGMyMDR3NSIsInVpZCI6IjAwdTJxNXAzQUFBT1hvU2MwNHc1Iiwic2NwIjpbIm9mZmxpbmVfYWNjZXNzIiwicHJvZmlsZSIsIm9wZW5pZCJdLCJzdWIiOiJhcnRodXIuZGVudEBleGFtcGxlLmNvbSJ9.kTP4UkaSAiBtAwb3hvI5JKUDFMr65CyLfy2a3t38eZI"
    let idToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJzdWIiOiIwMHUycTVwM2FjVk9Yb1NjMDR3NSIsIm5hbWUiOiJBcnRodXIgRGVudCIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTNlbjRmSU1RM2RkYzIwNHc1IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImp0aSI6IklELmJyNFdtM29RR2RqMGZzOFNDR3JLckNrX09pQmd1dEdya2dtZGk5VU9wZTgiLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzJxNWhtTEFFWFRuWmxoNHc1IiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYXJ0aHVyLmRlbnRAZXhhbXBsZS5jb20iLCJhdXRoX3RpbWUiOjE2NDI1MzI1NjEsImF0X2hhc2giOiJXbGN3enQtczNzeE9xMFlfRFNzcGFnIn0.Re3pBIYz7UauY61gdAHixVAXmgWMoHi_2Rx1-xuDvIs"

    func testAccessToken() throws {
        let token = try JWT(accessToken)
        XCTAssertEqual(token.subject, "arthur.dent@example.com")
        XCTAssertEqual(token.scope, ["offline_access", "profile", "openid"])
        XCTAssertEqual(token[.userId], "00u2q5p3AAAOXoSc04w5")
        XCTAssertEqual(token[.clientId], "0oa3en4fAAA3ddc204w5")
        XCTAssertEqual(token.issuer, "https://example.com/oauth2/default")
        XCTAssertNil(token.audience)
        XCTAssertEqual(token.expirationTime?.timeIntervalSinceReferenceDate, 664228962.0)
        XCTAssertEqual(token.issuedAt?.timeIntervalSinceReferenceDate, 664225362.0)
        XCTAssertNil(token.notBefore)
        XCTAssertEqual(token.expiresIn, 0)
        XCTAssertEqual(token.scope, ["offline_access", "profile", "openid"])
        
        XCTAssertEqual(token.claims.sorted(by: { $0.rawValue < $1.rawValue }), [
            .audience,
            .clientId,
            .expirationTime,
            .issuedAt,
            .issuer,
            .jwtId,
            .scope,
            .subject,
            .userId,
            .version
        ])
        
        XCTAssertEqual(token.customClaims, [])
        XCTAssertEqual(token.payload.reduce(into: [String:String](), { partialResult, item in
            guard let value = item.value as? String else { return }
            partialResult[item.key] = value
        }), [
            "jti": "AT.J6jlMcZyNy1Vi6rzkLB0lq2c0lHqEJ8pHct4uzilak0.oar9eazyLjAm6mwZG4w4",
            "aud": "api://default",
            "uid": "00u2q5p3AAAOXoSc04w5",
            "cid": "0oa3en4fAAA3ddc204w5",
            "sub": "arthur.dent@example.com",
            "iss": "https://example.com/oauth2/default"
        ])
        
        XCTAssertEqual(token.payload.reduce(into: [String:Array<String>](), { partialResult, item in
            guard let value = item.value as? Array<String> else { return }
            partialResult[item.key] = value
        }), [
            "scp": ["offline_access", "profile", "openid"]
        ])

        XCTAssertEqual(token.payload.reduce(into: [String:Bool](), { partialResult, item in
            guard let value = item.value as? Bool else { return }
            partialResult[item.key] = value
        }), [
            "ver": true
        ])
    }

    func testIdToken() throws {
        let token = try JWT(idToken)
        XCTAssertEqual(token[.preferredUsername], "arthur.dent@example.com")
        XCTAssertEqual(token[.name], "Arthur Dent")
    }

    func testAuthMethods() throws {
        let token = try JWT(idToken)
        XCTAssertEqual(token.authenticationMethods, [.passwordBased])
    }
}
