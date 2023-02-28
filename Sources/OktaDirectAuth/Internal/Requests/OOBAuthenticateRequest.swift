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

extension OpenIdConfiguration {
    var oobAuthenticateEndpoint: URL? {
        guard var components = URLComponents(url: tokenEndpoint, resolvingAgainstBaseURL: true),
            let tokenRange = components.path.range(of: "/token")
        else {
            return nil
        }
        components.path.replaceSubrange(tokenRange, with: "/oob-authenticate")
        return components.url
    }
}

struct OOBAuthenticateRequest {
    let url: URL
    let clientId: String
    let loginHint: String
    let channelHint: DirectAuthenticationFlow.Channel
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientId: String,
         loginHint: String,
         channelHint: DirectAuthenticationFlow.Channel) throws
    {
        guard let url = openIdConfiguration.oobAuthenticateEndpoint else {
            throw OAuth2Error.cannotComposeUrl
        }
        
        self.url = url
        self.clientId = clientId
        self.loginHint = loginHint
        self.channelHint = channelHint
    }
    
    struct Response: Codable {
        let oobCode: String
        let expiresIn: TimeInterval
        let interval: TimeInterval
        let channel: DirectAuthenticationFlow.Channel
        let bindingMethod: BindingMethod
    }
}

enum BindingMethod: String, Codable {
    case none
}

extension OOBAuthenticateRequest: APIRequest, APIRequestBody {
    typealias ResponseType = OOBAuthenticateRequest.Response

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        [
            "client_id": clientId,
            "login_hint": loginHint,
            "channel_hint": channelHint.rawValue
        ]
    }
}
