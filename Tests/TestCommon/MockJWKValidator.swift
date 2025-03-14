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
@testable import AuthFoundation

extension JWT {
    static let mockAccessToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJ2ZXIiOjEsImp0aSI6IkFULko2amxNY1p5TnkxVmk2cnprTEIwbHEyYzBsSHFFSjhwSGN0NHV6aWxhazAub2FyOWVhenlMakFtNm13Wkc0dzQiLCJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTY0MjUzMjU2MiwiZXhwIjoxNjQyNTM2MTYyLCJjaWQiOiIwb2EzZW40ZkFBQTNkZGMyMDR3NSIsInVpZCI6IjAwdTJxNXAzQUFBT1hvU2MwNHc1Iiwic2NwIjpbIm9mZmxpbmVfYWNjZXNzIiwicHJvZmlsZSIsIm9wZW5pZCJdLCJzdWIiOiJhcnRodXIuZGVudEBleGFtcGxlLmNvbSJ9.kTP4UkaSAiBtAwb3hvI5JKUDFMr65CyLfy2a3t38eZI"

    static let mockIDToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6Ims2SE4yREtvay1rRXhqSkdCTHFnekJ5TUNuTjFSdnpFT0EtMXVrVGpleEEifQ.eyJzdWIiOiIwMHUycTVwM2FjVk9Yb1NjMDR3NSIsIm5hbWUiOiJBcnRodXIgRGVudCIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6IjBvYTNlbjRmSU1RM2RkYzIwNHc1IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImp0aSI6IklELmJyNFdtM29RR2RqMGZzOFNDR3JLckNrX09pQmd1dEdya2dtZGk5VU9wZTgiLCJhbXIiOlsicHdkIl0sImlkcCI6IjAwbzJxNWhtTEFFWFRuWmxoNHc1IiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYXJ0aHVyLmRlbnRAZXhhbXBsZS5jb20iLCJhdXRoX3RpbWUiOjE2NDI1MzI1NjEsImF0X2hhc2giOiJXbGN3enQtczNzeE9xMFlfRFNzcGFnIn0.Re3pBIYz7UauY61gdAHixVAXmgWMoHi_2Rx1-xuDvIs"
}

struct MockJWKValidator: JWKValidator {
    var error: JWTError?
    var result: Bool = true
    
    func validate(token: JWT, using keySet: JWKS) throws -> Bool {
        if let error = error {
            throw error
        }
        return result
    }
}
