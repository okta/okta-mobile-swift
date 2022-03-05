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
        send(request, completion: completion)
    }
    
    func verify(result: Result<APIResponse<Token>, APIClientError>) -> Result<Token, APIClientError> {
        guard case let .success(response) = result,
              let idToken = response.result.idToken
        else {
            switch result {
            case .success(let response):
                return .success(response.result)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        do {
            let jwt = try JWT(idToken)
            try validate(jwt)
            
            if let key = jwks?[jwt.header.keyId],
               !(try JWT.validator.verify(token: jwt, using: key))
            {
                return .failure(.validation(error: OAuth2Error.signatureInvalid))
            }
        } catch {
            return .failure(.validation(error: error))
        }

        return .success(response.result)
    }
    
    func device(authorize request: DeviceAuthorizationFlow.AuthorizeRequest, completion: @escaping (Result<APIResponse<DeviceAuthorizationFlow.Context>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }
}
