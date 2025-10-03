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

struct OOBResponse: Codable, Equatable, HasTokenParameters, JSONDecodable {
    let oobCode: String
    let expiresIn: TimeInterval
    let interval: TimeInterval?
    let channel: DirectAuthenticationFlow.OOBChannel
    let bindingMethod: BindingMethod
    let bindingCode: String?

    init(oobCode: String, expiresIn: TimeInterval, interval: TimeInterval?, channel: DirectAuthenticationFlow.OOBChannel, bindingMethod: BindingMethod, bindingCode: String? = nil) {
        self.oobCode = oobCode
        self.expiresIn = expiresIn
        self.interval = interval
        self.channel = channel
        self.bindingMethod = bindingMethod
        self.bindingCode = bindingCode
    }
    
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: any APIRequestArgument] {
        ["oob_code": oobCode]
    }
    
    static var jsonDecoder: JSONDecoder {
        let result = JSONDecoder()
        result.keyDecodingStrategy = .convertFromSnakeCase
        return result
    }

    static func == (lhs: OOBResponse, rhs: OOBResponse) -> Bool {
        let tolerance: TimeInterval = 0.000001
        
        return lhs.oobCode == rhs.oobCode
        && abs(lhs.expiresIn - rhs.expiresIn) < tolerance
        && abs((lhs.interval ?? 0) - (rhs.interval ?? 0)) < tolerance
        && lhs.channel == rhs.channel
        && lhs.bindingMethod == rhs.bindingMethod
        && lhs.bindingCode == rhs.bindingCode
    }
}

struct OOBAuthenticateRequest: AuthenticationFlowRequest {
    typealias Flow = DirectAuthenticationFlow
    
    let url: URL
    let clientConfiguration: OAuth2Client.Configuration
    let context: Flow.Context
    let loginHint: String
    let channelHint: DirectAuthenticationFlow.OOBChannel
    let challengeHint: GrantType
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         context: DirectAuthenticationFlow.Context,
         loginHint: String,
         channelHint: DirectAuthenticationFlow.OOBChannel,
         challengeHint: GrantType) throws
    {
        guard let url = openIdConfiguration.primaryAuthenticateEndpoint else {
            throw OAuth2Error.cannotComposeUrl
        }
        
        self.url = url
        self.clientConfiguration = clientConfiguration
        self.context = context
        self.loginHint = loginHint
        self.channelHint = channelHint
        self.challengeHint = challengeHint
    }
}

enum BindingMethod: String, Codable, Equatable {
    case none
    case transfer
    case prompt
}

extension OOBAuthenticateRequest: APIRequest, APIRequestBody {
    typealias ResponseType = OOBResponse

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: AuthFoundation.OAuth2APIRequestCategory { .other }

    var bodyParameters: [String: any APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        result.merge(context.parameters(for: category))
        result.merge([
            "login_hint": loginHint,
            "channel_hint": channelHint,
            "challenge_hint": challengeHint,
        ])
        
        if result["client_id"] == nil {
            result["client_id"] = clientConfiguration.clientId
        }
        
        return result
    }
}
