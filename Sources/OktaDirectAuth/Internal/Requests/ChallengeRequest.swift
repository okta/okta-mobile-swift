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

struct ChallengeRequest: AuthenticationFlowRequest {
    typealias Flow = DirectAuthenticationFlow
    
    let url: URL
    let clientConfiguration: OAuth2Client.Configuration
    let context: Flow.Context
    let mfaToken: String
    let challengeTypesSupported: [GrantType]
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         context: DirectAuthenticationFlow.Context,
         mfaToken: String,
         challengeTypesSupported: [GrantType]) throws
    {
        guard let url = openIdConfiguration.challengeEndpoint else {
            throw OAuth2Error.cannotComposeUrl
        }
        
        self.url = url
        self.clientConfiguration = clientConfiguration
        self.context = context
        self.mfaToken = mfaToken
        self.challengeTypesSupported = challengeTypesSupported
    }
    
    struct Response: Codable, JSONDecodable {
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
        
        static var jsonDecoder: JSONDecoder {
            let result = JSONDecoder()
            result.keyDecodingStrategy = .convertFromSnakeCase
            return result
        }
    }
}

extension ChallengeRequest: APIRequest, APIRequestBody {
    typealias ResponseType = ChallengeRequest.Response

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: AuthFoundation.OAuth2APIRequestCategory { .other }
    var bodyParameters: [String: any APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        result.merge(context.parameters(for: category))
        result.merge([
            "mfa_token": mfaToken,
            "challenge_types_supported": challengeTypesSupported
        ])
        
        if result["client_id"] == nil {
            result["client_id"] = clientConfiguration.clientId
        }

        return result
    }
}
