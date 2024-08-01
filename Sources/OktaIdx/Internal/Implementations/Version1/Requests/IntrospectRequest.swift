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

extension APIContentType {
    static let ionJson = APIContentType.other("application/ion+json; okta-version=1.0.0")
}

extension InteractionCodeFlow {
    struct IntrospectRequest {
        let url: URL
        let interactionHandle: String

        init(baseURL: URL, interactionHandle: String) throws {
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
                throw InteractionCodeFlowError.invalidUrl
            }
            
            components.path = "/idp/idx/introspect"
            
            guard let url = components.url else {
                throw InteractionCodeFlowError.invalidUrl
            }
            
            self.url = url
            self.interactionHandle = interactionHandle
        }
    }
}

extension InteractionCodeFlow.IntrospectRequest: APIRequest, APIRequestBody, ReceivesIDXResponse, ReturnsIDXError {
    typealias ResponseType = IonResponse
    
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .json }
    var acceptsType: APIContentType? { .ionJson }
    var bodyParameters: [String: APIRequestArgument]? {
        [
            "interactionHandle": interactionHandle
        ]
    }

    var codingUserInfo: [CodingUserInfoKey: Any]? {
        nil
    }
}
