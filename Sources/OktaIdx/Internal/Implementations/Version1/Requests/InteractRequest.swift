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
    struct InteractRequest {
        let url: URL
        let clientId: String
        let scope: String
        let redirectUri: URL
        let options: [InteractionCodeFlow.Option: Any]?
        let pkce: PKCE

        init(baseURL: URL,
             clientId: String,
             scope: String,
             redirectUri: URL,
             options: [InteractionCodeFlow.Option: Any]?,
             pkce: PKCE)
        {
            url = baseURL.appendingPathComponent("v1/interact")
            self.clientId = clientId
            self.scope = scope
            self.redirectUri = redirectUri
            self.options = options
            self.pkce = pkce
        }

        struct Response: Codable, ReceivesIDXResponse {
            let interactionHandle: String
        }
    }
}

extension InteractionCodeFlow.InteractRequest: APIRequest, APIRequestBody {
    typealias ResponseType = Response
    
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    
    var bodyParameters: [String: Any]? {
        var result: [String: Any] = [
            "client_id": clientId,
            "scope": scope,
            "redirect_uri": redirectUri.absoluteString,
            "code_challenge": pkce.codeChallenge,
            "code_challenge_method": pkce.method.rawValue
        ]
        
        options?.filter { $0.key.includeInInteractRequest }
            .compactMapValues { $0 as? String }
            .forEach { (key: InteractionCodeFlow.Option, value: String) in
                result[key.rawValue] = value
            }

        return result
    }
}
