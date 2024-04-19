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
@testable import TestCommon
@testable import OktaDirectAuth

final class WebAuthnResponseTests: XCTestCase {
    
    func testCreationResponse() throws {
        let response = try decode(type: WebAuthn.CredentialCreationOptions.self,
            """
            {
                "options": {
                    "rp": {
                        "name": "Rain-Cloud59",
                        "id": "rain"
                    },
                    "user": {
                        "displayName": "Add-Min O'Cloudy Tud",
                        "name": "administrator1@clouditude.net",
                        "id": "00uzq50n1sT58Lsbo0g3"
                    },
                    "pubKeyCredParams": [
                        {
                            "type": "public-key",
                            "alg": -7
                        },
                        {
                            "type": "public-key",
                            "alg": -257
                        }
                    ],
                    "challenge": "JY8E7VRQvBtaK02JHfTGWp2DcVKiRbKy",
                    "attestation": "direct",
                    "authenticatorSelection": {
                        "userVerification": "discouraged",
                        "requireResidentKey": true,
                        "residentKey": "required"
                    },
                    "u2fParams": {
                        "appid": "https://rain.okta1.com"
                    },
                    "excludeCredentials": []
                },
                "challengeId": "ftbSiVzP1qUw1vZLaAVyAXnirjf2x-Yy5W",
                "expiresAt": 1713484944325
            }
            """)
        
        print(response.options)
    }
}
