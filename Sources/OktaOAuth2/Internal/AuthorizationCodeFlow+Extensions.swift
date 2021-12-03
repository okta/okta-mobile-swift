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

extension AuthorizationCodeFlow.Configuration {
    func authenticationUrlComponents(using context: AuthorizationCodeFlow.Context) throws -> URLComponents {
        guard let url = URL(string: "authorize", relativeTo: baseURL),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        components.queryItems = queryParameters(using: context).map { (key, value) in
            URLQueryItem(name: key, value: value)
        }

        return components
    }
    
    private func queryParameters(using context: AuthorizationCodeFlow.Context) -> [String:String] {
        var parameters = additionalParameters ?? [:]
        parameters["client_id"] = clientId
        parameters["scope"] = scopes
        parameters["redirect_uri"] = redirectUri.absoluteString
        parameters["response_type"] = responseType.rawValue
        parameters["state"] = context.state

        if let pkce = context.pkce {
            parameters["code_challenge"] = pkce.codeChallenge
            parameters["code_challenge_method"] = pkce.method.rawValue
        }
        
        return parameters
    }
}

extension AuthorizationCodeFlow {
    func createAuthenticationURL(using context: AuthorizationCodeFlow.Context) throws -> URL {
        var components = try configuration.authenticationUrlComponents(using: context)
        delegateCollection.invoke { $0.authentication(flow: self, customizeUrl: &components) }

        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}
