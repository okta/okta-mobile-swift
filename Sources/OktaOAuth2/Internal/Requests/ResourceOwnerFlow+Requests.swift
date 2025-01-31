//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension ResourceOwnerFlow {
    struct TokenRequest: AuthenticationFlowRequest {
        typealias Flow = ResourceOwnerFlow
        
        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: APIRequestArgument]?
        let context: Flow.Context
        let username: String
        let password: String
    }
}

extension ResourceOwnerFlow.TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody, APIParsingContext {
    var category: AuthFoundation.OAuth2APIRequestCategory { .token }
    
    var bodyParameters: [String: APIRequestArgument]? {
        var result = additionalParameters ?? [:]
        result.merge(clientConfiguration.parameters(for: category))
        result.merge(context.parameters(for: category))
        result.merge([
            "grant_type": GrantType.password,
            "username": username,
            "password": password,
        ])
        return result
    }
}
