/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension IDXClient.APIVersion1.IntrospectRequest: IDXClientAPIRequest, ReceivesIDXResponse {
    typealias ResponseType = IDXClient.APIVersion1.Response
    
    init(interactionHandle: String) {
        requestBody = RequestBody(interactionHandle: interactionHandle)
    }
    
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest? {
        guard var urlComponents = URLComponents(string: configuration.issuer) else { return nil }
        urlComponents.path = "/idp/idx/introspect"
        
        guard let url = urlComponents.url else { return nil }

        let data: Data
        do {
            data = try JSONEncoder().encode(requestBody)
        } catch {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        httpHeaders.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }

        return request
    }
    
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
    {
        guard let request = urlRequest(using: configuration) else {
            completion(nil, IDXClientError.cannotCreateRequest)
            return
        }
        
        let task = session.dataTaskWithRequest(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            let result: ResponseType!
            do {
                result = try self.idxResponse(from: data)
            } catch {
                completion(nil, error)
                return
            }

            completion(result, nil)
        }
        task.resume()
    }
    
    struct RequestBody: Codable {
        let interactionHandle: String
    }
}
