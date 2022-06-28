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

extension IDXAuthenticationFlow {
    struct RemediationRequest {
        let httpMethod: APIRequestMethod
        let url: URL
        let contentType: APIContentType?
        let bodyParameters: [String: Any]?
    }
}

extension IDXAuthenticationFlow.RemediationRequest: APIRequest, APIRequestBody, ReceivesIDXResponse, ReturnsIDXError {
    typealias ResponseType = IonResponse
    
    init(remediation option: Remediation) throws {
        guard let acceptsString = option.accepts,
              let accepts = APIContentType(rawValue: acceptsString),
              let method = APIRequestMethod(rawValue: option.method)
        else {
            throw IDXAuthenticationFlowError.invalidRequestData
        }
        
        self.url = option.href
        self.httpMethod = method
        self.contentType = accepts
        self.bodyParameters = try option.form.formValues()
    }
    
    var acceptsType: APIContentType? { .ionJson }

    var codingUserInfo: [CodingUserInfoKey: Any]? {
        nil
    }
}
