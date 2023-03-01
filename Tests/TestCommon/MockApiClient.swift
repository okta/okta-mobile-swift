//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import AuthFoundation

class MockApiClient: APIClient {
    var baseURL: URL
    var session: URLSessionProtocol
    let configuration: APIClientConfiguration
    let shouldRetry: APIRetry?
    var request: URLRequest?
    var delegate: APIClientDelegate?
    
    init(configuration: APIClientConfiguration,
         session: URLSessionProtocol,
         baseURL: URL,
         shouldRetry: APIRetry? = nil) {
        self.configuration = configuration
        self.session = session
        self.baseURL = baseURL
        self.shouldRetry = shouldRetry
    }
    
    func decode<T>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey : Any]?) throws -> T where T : Decodable {
        var info: [CodingUserInfoKey: Any] = userInfo ?? [:]
        if info[.apiClientConfiguration] == nil {
            info[.apiClientConfiguration] = configuration
        }
        
        let jsonDecoder: JSONDecoder
        if let jsonType = type as? JSONDecodable.Type {
            jsonDecoder = jsonType.jsonDecoder
        } else {
            jsonDecoder = defaultJSONDecoder
        }
        
        jsonDecoder.userInfo = info
        
        return try jsonDecoder.decode(type, from: data)
    }
    
    func didSend(request: URLRequest, received error: AuthFoundation.APIClientError, requestId: String?, rateLimit: AuthFoundation.APIRateLimit?) {
        self.request = request
        delegate?.api(client: self, didSend: request, received: error, requestId: nil, rateLimit: nil)
    }
    
    func willSend(request: inout URLRequest) {
        self.request = request
        delegate?.api(client: self, willSend: &request)
    }
    
    func shouldRetry(request: URLRequest, rateLimit: APIRateLimit) -> APIRetry {
        shouldRetry ?? delegate?.api(client: self, shouldRetry: request) ?? .default
    }
}
