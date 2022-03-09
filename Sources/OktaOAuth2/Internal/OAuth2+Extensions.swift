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
@_exported import AuthFoundation

extension OAuth2Client {
    func exchange(token request: TokenRequest & APIRequest, completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void) {
        // Fetch the JWKS keys in parallel if necessary
        let group = DispatchGroup()
        var keySet = jwks
        if keySet == nil {
            group.enter()
            jwks { result in
                defer { group.leave() }
                if case let .success(response) = result {
                    keySet = response
                }
            }
        }
        
        // Exchange the token
        send(request) { (result: Result<APIResponse<Token>, APIClientError>) in
            guard case let .success(response) = result else {
                completion(result)
                return
            }
            
            // Perform idToken/accessToken validation
            do {
                try response.result.validate(using: self)
            } catch {
                completion(.failure(.validation(error: error)))
                return
            }
            
            // Wait for the JWKS keys, if necessary
            group.notify(queue: DispatchQueue.global()) {
                guard let idToken = response.result.idToken else {
                    completion(result)
                    return
                }
                
                guard let keySet = keySet else {
                    completion(.failure(.validation(error: JWTError.invalidKey)))
                    return
                }
                    
                do {
                    if try idToken.validate(using: keySet) == false {
                        completion(.failure(.validation(error: JWTError.signatureInvalid)))
                        return
                    }
                } catch {
                    completion(.failure(.validation(error: error)))
                    return
                }
                
                completion(result)
            }
        }
    }
    
    func device(authorize request: DeviceAuthorizationFlow.AuthorizeRequest, completion: @escaping (Result<APIResponse<DeviceAuthorizationFlow.Context>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }
}
