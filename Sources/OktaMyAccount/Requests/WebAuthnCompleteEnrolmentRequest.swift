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

import Foundation
import AuthFoundation
import OktaDirectAuth

#if os(Linux)
import FoundationNetworking
#endif

extension OAuth2Client {
    struct WebAuthnCompleteEnrolmentRequest {
        let url: URL
        let challengeId: String
        let attestationObject: String
        let clientDataJSON: String
        
        init(url: URL, challengeId: String, attestationObject: String, clientDataJSON: String) {
            self.url = url
            self.challengeId = challengeId
            self.attestationObject = attestationObject
            self.clientDataJSON = clientDataJSON
        }
        
        init(openIdConfiguration: OpenIdConfiguration, challengeId: String, attestationObject: String, clientDataJSON: String) throws {
            guard let url = URL(string: "/idp/myaccount/webauthn/enroll/complete",
                                relativeTo: openIdConfiguration.issuer)
            else {
                throw OAuth2Error.cannotComposeUrl
            }
            
            self.init(url: url,
                      challengeId: challengeId,
                      attestationObject: attestationObject,
                      clientDataJSON: clientDataJSON)
        }
    }
}

extension OAuth2Client.WebAuthnCompleteEnrolmentRequest: APIRequest, APIRequestBody {
    typealias ResponseType = WebAuthn.CredentialCreationResponse
    
    var httpMethod: APIRequestMethod { .get }
    var acceptsType: APIContentType? { .json }
    var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringLocalAndRemoteCacheData }
    var bodyParameters: [String : Any]? {
        return [
            "challengeId": challengeId,
            "enrollment": [
                "attestationObject": attestationObject,
                "clientDataJSON": clientDataJSON,
            ]
        ]
    }
}
