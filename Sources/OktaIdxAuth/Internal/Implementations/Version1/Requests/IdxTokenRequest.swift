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
import JSON

extension InteractionCodeFlow {
    struct TokenRequest: AuthenticationFlowRequest {
        typealias Flow = InteractionCodeFlow

        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: any APIRequestArgument]?
        let context: Flow.Context
        let interactionCode: String

        init(openIdConfiguration: OpenIdConfiguration, clientConfiguration: OAuth2Client.Configuration, additionalParameters: [String: any APIRequestArgument]?, context: Flow.Context, interactionCode: String) throws {
            guard clientConfiguration.redirectUri != nil else {
                throw OAuth2Error.redirectUriRequired
            }

            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.additionalParameters = additionalParameters
            self.context = context
            self.interactionCode = interactionCode
        }
    }

    struct SuccessResponseTokenRequest: AuthenticationFlowRequest {
        typealias Flow = InteractionCodeFlow

        let httpMethod: APIRequestMethod
        let url: URL
        let contentType: APIContentType?

        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: any APIRequestArgument]?
        let context: Flow.Context
        let formParameters: [String: any JSONRepresentable]

        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             additionalParameters: [String: any APIRequestArgument]?,
             context: Flow.Context,
             successRemediation option: Remediation) throws
        {
            guard clientConfiguration.redirectUri != nil else {
                throw OAuth2Error.redirectUriRequired
            }

            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.additionalParameters = additionalParameters
            self.context = context
            self.url = option.href
            self.httpMethod = option.method
            self.contentType = option.accepts
            self.formParameters = option.form.allFields.reduce(into: [:]) { partialResult, field in
                if let name = field.name,
                   let value = field.value,
                   value.json != .null
                {
                    partialResult[name] = value
                }
            }

            if let clientId = formParameters["client_id"] as? String,
               clientId != clientConfiguration.clientId
            {
                throw InteractionCodeFlowError.invalidParameter(name: "client_id")
            }
        }
    }
}

extension InteractionCodeFlow.TokenRequest: OAuth2TokenRequest, APIRequestBody, APIParsingContext {
    var category: AuthFoundation.OAuth2APIRequestCategory { .token }
    var tokenValidatorContext: any IDTokenValidatorContext { context }

    var bodyParameters: [String: any APIRequestArgument]? {
        let grantType = GrantType.interactionCode
        var result = additionalParameters ?? [:]
        result.merge(clientConfiguration.parameters(for: category))
        result.merge(context.parameters(for: category))
        result.merge([
            "grant_type": grantType.rawValue,
            grantType.rawValue: interactionCode,
        ])

        return result
    }
}

extension InteractionCodeFlow.SuccessResponseTokenRequest: OAuth2TokenRequest, APIRequestBody, APIParsingContext {
    var acceptsType: APIContentType? { .other("application/json") }
    var category: AuthFoundation.OAuth2APIRequestCategory { .token }
    var tokenValidatorContext: any IDTokenValidatorContext { context }

    var bodyParameters: [String: any APIRequestArgument]? {
        var result = additionalParameters ?? [:]
        result.merge(clientConfiguration.parameters(for: category))
        result.merge(context.parameters(for: category))
        result.merge(formParameters.compactMapValues({ $0.json.anyValue as? (any APIRequestArgument) }))
        return result
    }
}
