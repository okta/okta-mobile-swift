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
    struct RemediationRequest {
        let httpMethod: APIRequestMethod
        let url: URL
        let contentType: APIContentType?
        let bodyParameters: [String: Any]?
    }
}

extension InteractionCodeFlow.RemediationRequest: APIRequest, APIRequestBody, ReceivesIDXResponse, ReturnsIDXError {
    typealias ResponseType = IonResponse
    
    init(remediation option: Remediation) throws {
        guard let acceptsString = option.accepts,
              let accepts = APIContentType(rawValue: acceptsString),
              let method = APIRequestMethod(rawValue: option.method)
        else {
            throw InteractionCodeFlowError.invalidRequestData
        }
        
        self.url = option.href
        self.httpMethod = method
        self.contentType = accepts
        self.bodyParameters = try option.form.formValues()
    }
    
    var acceptsType: APIContentType? { .ionJson }
}

extension InteractionCodeFlow.RemediationRequest: APIParsingContext {
    func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        switch response.statusCode {
        case 429:
            return .retry
        case 200..<500:
            // IDX returns error codes that contain valid ION responses, meaning
            // such errors are not terminal and should be reported to the developer
            // with its full payload.
            return .success
        default:
            return .error
        }
    }

    var codingUserInfo: [CodingUserInfoKey: Any]? {
        nil
    }
}
