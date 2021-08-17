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

extension IDXClient.APIVersion1.InteractRequest: IDXClientAPIRequest {
    static let challengeMethod = "S256"
    
    typealias ResponseType = Response
    
    init(state: String?, codeChallenge: String) {
        self.state = state ?? UUID().uuidString
        self.codeChallenge = codeChallenge
    }
    
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest? {
        guard let url = configuration.issuerUrl(with: "v1/interact") else { return nil }

        let params = [
            "client_id": configuration.clientId,
            "scope": configuration.scopes.joined(separator: " "),
            "code_challenge": codeChallenge,
            "code_challenge_method": "S256",
            "redirect_uri": configuration.redirectUri,
            "state": state
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = URLRequest.idxURLFormEncodedString(for: params)?.data(using: .utf8)
        httpHeaders.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }

        return request
    }
    
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (Result<ResponseType, IDXClientError>) -> Void)
    {
        guard let request = urlRequest(using: configuration) else {
            completion(.failure(.cannotCreateRequest))
            return
        }
        
        let task = session.dataTaskWithRequest(with: request) { (data, response, error) in
            guard error == nil else {
                completion(.failure(.internalError(error!)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponseData))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result: ResponseType!
            do {
                result = try decoder.decode(ResponseType.self, from: data)
            } catch {
                completion(.failure(.internalError(error)))
                return
            }

            completion(.success(result))
        }
        task.resume()
    }
    
    struct Response: Codable {
        let interactionHandle: String
    }
}
