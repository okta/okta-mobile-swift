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

import Foundation
import XCTest
import TestCommon

@testable import AuthFoundation

final class JWTValidatorTests: XCTestCase {
    func testValidator() throws {
        let keyData = try data(from: .module, for: "keys", in: "MockResponses")
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        let key = try XCTUnwrap(jwks.first)

        let jwt = try JWT("eyJhbGciOiJSUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJzdWIiOiIwMHUycTVwM2FjVk9Yb1NjMDR3NSIsIm5hbWUiOiJBcnRodXIgRGVudCIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTNlbjRmSU1RM2RkYzIwNHc1IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImp0aSI6IklELmJyNFdtM29RR2RqMGZzOFNDR3JLckNrX09pQmd1dEdya2dtZGk5VU9wZTgiLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzJxNWhtTEFFWFRuWmxoNHc1IiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYXJ0aHVyLmRlbnRAZXhhbXBsZS5jb20iLCJhdXRoX3RpbWUiOjE2NDI1MzI1NjEsImF0X2hhc2giOiJXbGN3enQtczNzeE9xMFlfRFNzcGFnIn0.hMcCg_SVy6TKC7KpHRfW484p-jxxdyKf5koWESFDoaouC_uEmtJr7KzpwYYkRM5A2T7_GuQ3E9dSv1l1M9Pp1b2fVIXHiCXTj9whbx97-xyTAT5HqQY_-nk_xUIYqzNOqWCMrP2PxZ4erRl_iRhu0KyL4neIalDIbnHPopzlALn-RRBHyyU9NHGXeyMWGhEV3NLmSIxVQWiwAySKxM5GbafHLvVhK2uJxCqQG6GPU5MwxkdJe_3W2Lvefv9iUn_YJENFF54Ph8NTuJzz6ccep6haHuEMpBZny9qd1fbITxMJi9dAPEbGm9ne9ch5gO7skPHTg-KFl90eIaU-zoKK-w")
        
        let validator = DefaultJWTValidator()
        #if os(Linux)
        XCTAssertThrowsError(try validator.verify(token: jwt, using: key))
        #else
        XCTAssertNoThrow(try validator.verify(token: jwt, using: key))
        #endif
    }
}
