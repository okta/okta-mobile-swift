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
    func createAuthenticationURL(from authenticationUrl: URL,
                                 using context: AuthorizationCodeFlow.Context) throws -> URL
    {
        guard client.configuration.redirectUri != nil else {
            throw OAuth2Error.missingRedirectUri
        }
        
        guard var components = URLComponents(url: authenticationUrl, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        var parameters = additionalParameters ?? [:]
        parameters.merge(client.configuration.parameters(for: .authorization))
        parameters.merge(context.parameters(for: .authorization))
        
        components.percentEncodedQuery = parameters
            .mapValues(\.stringValue)
            .percentQueryEncoded
        
        delegateCollection.invoke { $0.authentication(flow: self, customizeUrl: &components) }

        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}
