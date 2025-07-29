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

import Testing
@testable import AuthFoundation
import TestCommon

@Suite("JWT Tests")
struct JWTTests {
    let accessToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJ2ZXIiOjEsImp0aSI6IkFULko2amxNY1p5TnkxVmk2cnprTEIwbHEyYzBsSHFFSjhwSGN0NHV6aWxhazAub2FyOWVhenlMakFtNm13Wkc0dzQiLCJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTY0MjUzMjU2MiwiZXhwIjoxNjQyNTM2MTYyLCJjaWQiOiIwb2EzZW40ZkFBQTNkZGMyMDR3NSIsInVpZCI6IjAwdTJxNXAzQUFBT1hvU2MwNHc1Iiwic2NwIjpbIm9mZmxpbmVfYWNjZXNzIiwicHJvZmlsZSIsIm9wZW5pZCJdLCJzdWIiOiJhcnRodXIuZGVudEBleGFtcGxlLmNvbSJ9.kTP4UkaSAiBtAwb3hvI5JKUDFMr65CyLfy2a3t38eZI"
    let idToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJzdWIiOiIwMHUycTVwM2FjVk9Yb1NjMDR3NSIsIm5hbWUiOiJBcnRodXIgRGVudCIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTNlbjRmSU1RM2RkYzIwNHc1IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImp0aSI6IklELmJyNFdtM29RR2RqMGZzOFNDR3JLckNrX09pQmd1dEdya2dtZGk5VU9wZTgiLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzJxNWhtTEFFWFRuWmxoNHc1IiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYXJ0aHVyLmRlbnRAZXhhbXBsZS5jb20iLCJhdXRoX3RpbWUiOjE2NDI1MzI1NjEsImF0X2hhc2giOiJXbGN3enQtczNzeE9xMFlfRFNzcGFnIn0.Re3pBIYz7UauY61gdAHixVAXmgWMoHi_2Rx1-xuDvIs"

    @Test("Access Token parsing and validation")
    func testAccessToken() throws {
        let token = try JWT(self.accessToken)
        #expect(token.subject == "arthur.dent@example.com")
        #expect(token.scope == ["offline_access", "profile", "openid"])
        #expect(token[.userId] as String? == "00u2q5p3AAAOXoSc04w5")
        #expect(token[.clientId] as String? == "0oa3en4fAAA3ddc204w5")
        #expect(token.issuer == "https://example.com/oauth2/default")
        #expect(token.audience == "api://default")
        #expect(token.expirationTime?.timeIntervalSinceReferenceDate == 664228962.0)
        #expect(token.issuedAt?.timeIntervalSinceReferenceDate == 664225362.0)
        #expect(token.notBefore == nil)
        #expect(token.expiresIn == 0)
        #expect(token.scope == ["offline_access", "profile", "openid"])
        
        #expect(token.claims.sorted(by: { $0.rawValue < $1.rawValue }) == [
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
        
        #expect(token.customClaims == [])
        #expect(token.payload.reduce(into: [String:String](), { partialResult, item in
            guard let value = item.value as? String else { return }
            partialResult[item.key] = value
        }) == [
            "jti": "AT.J6jlMcZyNy1Vi6rzkLB0lq2c0lHqEJ8pHct4uzilak0.oar9eazyLjAm6mwZG4w4",
            "aud": "api://default",
            "uid": "00u2q5p3AAAOXoSc04w5",
            "cid": "0oa3en4fAAA3ddc204w5",
            "sub": "arthur.dent@example.com",
            "iss": "https://example.com/oauth2/default"
        ])
        
        #expect(token.payload.reduce(into: [String:Array<String>](), { partialResult, item in
            guard let value = item.value as? Array<String> else { return }
            partialResult[item.key] = value
        }) == [
            "scp": ["offline_access", "profile", "openid"]
        ])

        #expect(token.payload.reduce(into: [String:Bool](), { partialResult, item in
            guard let value = item.value as? Bool else { return }
            partialResult[item.key] = value
        }) == [
            "ver": true
        ])
    }

    @Test("ID Token parsing and validation")
    func testIdToken() throws {
        let token = try JWT(self.idToken)
        #expect(token[.preferredUsername] as String? == "arthur.dent@example.com")
        #expect(token[.name] as String? == "Arthur Dent")
    }

    @Test("Authentication Methods parsing")
    func testAuthMethods() throws {
        let token = try JWT(self.idToken)
        #expect(token.authenticationMethods == [.passwordBased])
    }
}
