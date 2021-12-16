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

extension IDXClient.APIVersion1.TokenRequest: IDXClientAPIRequest {
    typealias ResponseType = IDXClient.APIVersion1.IonToken
    
    init(successResponse option: Remediation) throws {
        guard let accepts = option.accepts,
              let acceptType = IDXClient.APIVersion1.AcceptType(rawValue: accepts) else
        {
            throw IDXClientError.invalidRequestData
        }
        
        self.init(method: option.method,
                  href: option.href,
                  accepts: acceptType,
                  parameters: try option.form.formValues())
    }
    
    init(issuer url: URL, clientId: String, clientSecret: String?, codeVerifier: String?, grantType: String, code: String) {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        let path = urlComponents?.path ?? ""
        urlComponents?.path = path + "/v1/token"
        
        let tokenUrl = urlComponents?.url ?? url
        
        var parameters = [
            "client_id": clientId,
            "grant_type": grantType,
            grantType: code
        ]
        
        if let clientSecret = clientSecret {
            parameters["client_secret"] = clientSecret
        }
        
        if let codeVerifier = codeVerifier {
            parameters["code_verifier"] = codeVerifier
        }
        
        self.init(method: "POST",
                  href: tokenUrl,
                  accepts: .formEncoded,
                  parameters: parameters)
    }
    
    func urlRequest(using configuration: IDXClient.Configuration) -> URLRequest? {
        let data: Data?
        do {
            data = try accepts.encodedData(with: parameters)
        } catch {
            return nil
        }

        var request = URLRequest(url: href)
        request.httpMethod = method
        request.httpBody = data
        request.addValue(accepts.stringValue(), forHTTPHeaderField: "Content-Type")
        httpHeaders.forEach { (key, value) in
            if request.allHTTPHeaderFields?[key] == nil {
                request.setValue(value, forHTTPHeaderField: key)
            }
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
}
