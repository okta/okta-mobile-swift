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

#if os(Linux) || os(Android)
import FoundationNetworking
#endif

extension InteractionCodeFlow {
    struct RemediationRequest {
        let httpMethod: APIRequestMethod
        let url: URL
        let contentType: APIContentType?
        let bodyParameters: [String: any Sendable]?
    }
}

extension InteractionCodeFlow.RemediationRequest: APIRequest, ReceivesIDXResponse, ReturnsIDXError {
    typealias ResponseType = IonResponse
    
    init(remediation option: Remediation) throws {
        self.url = option.href
        self.httpMethod = option.method
        self.contentType = option.accepts
        self.bodyParameters = try option.form.formValues().json.anyValue as? [String: any Sendable]
    }
    
    var acceptsType: APIContentType? { .ionJson }
    
    func body() throws -> Data? {
        guard let bodyParameters = bodyParameters else {
            return nil
        }
        return try JSONSerialization.data(withJSONObject: bodyParameters)
    }
}

extension InteractionCodeFlow.RemediationRequest: APIParsingContext {
    func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        switch response.statusCode {
        case 429:
            // Ignore rate-limit responses for particular endpoints that
            // misrepresent legitimate responses as rate-limit errors.
            if let path = response.url?.path,
               path.hasSuffix("/idp/idx/challenge/answer")
            {
                return .success
            }
            
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
