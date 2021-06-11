//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient.APIVersion1.RevokeRequest: IDXClientAPIRequest {
    typealias ResponseType = Bool
    
    func urlRequest(using configuration: IDXClient.Configuration) -> URLRequest? {
        let parameters = [
            "client_id": configuration.clientId,
            "token": token,
            "token_type_hint": tokenTypeHint
        ]
        
        guard let data = URLRequest.idxURLFormEncodedString(for: parameters)?.data(using: .utf8) else { return nil }
        guard var urlComponents = URLComponents(string: configuration.issuer) else { return nil }
        urlComponents.path = "/oauth2/v1/revoke"
        
        guard let url = urlComponents.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        httpHeaders.forEach { (key, value) in
            if request.allHTTPHeaderFields?[key] == nil {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        return request
    }

    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
    {
        guard let request = urlRequest(using: configuration) else {
            completion(false, IDXClientError.cannotCreateRequest)
            return
        }
        
        let task = session.dataTaskWithRequest(with: request) { (data, response, error) in
            guard error == nil else {
                completion(false, error)
                return
            }
            
            guard let data = data else {
                completion(false, IDXClientError.invalidResponseData)
                return
            }
            
            guard response?.statusCode == 200 else {
                let oauthError = try? JSONDecoder().decode(IDXClient.APIVersion1.OAuth2Error.self, from: data)
                completion(false, oauthError ?? error)
                return
            }
            
            completion(true, nil)
        }
        task.resume()
    }
}
