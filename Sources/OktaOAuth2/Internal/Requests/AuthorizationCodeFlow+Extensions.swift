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

extension AuthorizationCodeFlow {
    func authenticationUrlComponents(from authenticationUrl: URL,
                                     using context: AuthorizationCodeFlow.Context,
                                     additionalParameters: [String: String]?) throws -> URLComponents
    {
        guard var components = URLComponents(url: authenticationUrl, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        components.percentEncodedQuery = queryParameters(using: context,
                                                         additionalParameters: additionalParameters).percentQueryEncoded

        return components
    }
    
    private func queryParameters(using context: AuthorizationCodeFlow.Context,
                                 additionalParameters: [String: String]?) -> [String: String]
    {
        var parameters = [String: String]()
        if let additional = self.additionalParameters {
            parameters.merge(additional, uniquingKeysWith: { $1 })
        }
        
        if let additional = additionalParameters {
            parameters.merge(additional, uniquingKeysWith: { $1 })
        }
        
        parameters["client_id"] = client.configuration.clientId
        parameters["scope"] = client.configuration.scopes
        parameters["redirect_uri"] = redirectUri.absoluteString
        parameters["response_type"] = "code"
        parameters["state"] = context.state
        parameters["nonce"] = context.nonce

        if let pkce = context.pkce {
            parameters["code_challenge"] = pkce.codeChallenge
            parameters["code_challenge_method"] = pkce.method.rawValue
        }
        
        return parameters
    }

    func createAuthenticationURL(from authenticationUrl: URL,
                                 using context: AuthorizationCodeFlow.Context,
                                 additionalParameters: [String: String]?) throws -> URL
    {
        var components = try authenticationUrlComponents(from: authenticationUrl,
                                                         using: context,
                                                         additionalParameters: additionalParameters)
        delegateCollection.invoke { $0.authentication(flow: self, customizeUrl: &components) }

        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}
