//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension OpenIdConfiguration {
    var challengeEndpoint: URL? {
        tokenEndpoint.url(replacing: "/token", with: "/challenge")
    }
}

struct ChallengeRequest {
    let url: URL
    let clientConfiguration: OAuth2Client.Configuration
    let mfaToken: String
    let challengeTypesSupported: [GrantType]
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         mfaToken: String,
         challengeTypesSupported: [GrantType]) throws
    {
        guard let url = openIdConfiguration.challengeEndpoint else {
            throw OAuth2Error.cannotComposeUrl
        }
        
        self.url = url
        self.clientConfiguration = clientConfiguration
        self.mfaToken = mfaToken
        self.challengeTypesSupported = challengeTypesSupported
    }
    
    struct Response: Codable {
        let challengeType: GrantType
        let oobCode: String?
        let expiresIn: TimeInterval?
        let interval: TimeInterval?
        let channel: DirectAuthenticationFlow.OOBChannel?
        let bindingMethod: BindingMethod?
        let bindingCode: String?
        
        var oobResponse: OOBResponse? {
            guard let oobCode = oobCode,
                  let expiresIn = expiresIn,
                  let interval = interval,
                  let channel = channel,
                  let bindingMethod = bindingMethod
            else {
                return nil
            }
            
            return .init(oobCode: oobCode,
                         expiresIn: expiresIn,
                         interval: interval,
                         channel: channel,
                         bindingMethod: bindingMethod,
                         bindingCode: bindingCode)
        }
    }
}

extension ChallengeRequest: APIRequest, APIRequestBody {
    typealias ResponseType = ChallengeRequest.Response

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        var result: [String: Any] = [
            "client_id": clientConfiguration.clientId,
            "mfa_token": mfaToken,
            "challenge_types_supported": challengeTypesSupported
                .map(\.rawValue)
                .joined(separator: " ")
        ]
        
        if let parameters = clientConfiguration.authentication.additionalParameters {
            result.merge(parameters, uniquingKeysWith: { $1 })
        }

        return result
    }
}
