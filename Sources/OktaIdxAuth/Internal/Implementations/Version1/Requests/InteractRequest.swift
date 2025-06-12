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

extension InteractionCodeFlow {
    struct InteractRequest: AuthenticationFlowRequest {
        typealias Flow = InteractionCodeFlow

        let url: URL
        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: any APIRequestArgument]?
        let context: Flow.Context

        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             additionalParameters: [String: any APIRequestArgument]?,
             context: Flow.Context) throws
        {
            guard let url = openIdConfiguration.interactEndpoint else {
                throw OAuth2Error.invalidUrl
            }
            self.url = url
            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.additionalParameters = additionalParameters
            self.context = context
        }

        struct Response: Codable, ReceivesIDXResponse {
            let interactionHandle: String
        }
    }
}

extension InteractionCodeFlow.InteractRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = Response
    
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: AuthFoundation.OAuth2APIRequestCategory { .authorization }

    var bodyParameters: [String: any APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        result.merge(context.parameters(for: category))
        return result
    }
}
