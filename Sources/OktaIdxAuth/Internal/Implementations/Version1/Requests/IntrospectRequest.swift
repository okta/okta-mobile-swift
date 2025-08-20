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
    struct IntrospectRequest {
        let url: URL
        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: any APIRequestArgument]?
        let context: InteractionCodeFlow.Context
        let interactionHandle: String

        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             additionalParameters: [String: any APIRequestArgument]?,
             context: InteractionCodeFlow.Context) throws
        {
            guard let url = openIdConfiguration.introspectEndpoint else {
                throw OAuth2Error.invalidUrl
            }

            guard let interactionHandle = context.interactionHandle else {
                throw OAuth2Error.invalidContext
            }

            self.url = url
            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.additionalParameters = additionalParameters
            self.context = context
            self.interactionHandle = interactionHandle
        }
    }
}

extension InteractionCodeFlow.IntrospectRequest: APIRequest, APIRequestBody, ReturnsIDXError {
    typealias ResponseType = IonResponse
    
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .json }
    var acceptsType: APIContentType? { .ionJson }
    var category: AuthFoundation.OAuth2APIRequestCategory { .other }

    var bodyParameters: [String: any APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        result.merge(context.parameters(for: category))
        result.merge([
            "interactionHandle": interactionHandle,
        ])
        return result
    }
}
