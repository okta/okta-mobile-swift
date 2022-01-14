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

extension OAuth2Client {
    func fetchOpenIdConfiguration(completion: @escaping (Result<APIResponse<OpenIdConfiguration>, APIClientError>) -> Void) {
        send(OpenIdConfigurationRequest(), completion: completion)
    }

    func refresh(_ request: Token.RefreshRequest, completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }

    func revoke(_ request: Token.RevokeRequest, completion: @escaping (Result<APIResponse<Empty>, APIClientError>) -> Void) {
//        send(request, completion: completion)
    }

    func introspect(_ request: Token.IntrospectRequest, completion: @escaping (Result<APIResponse<[String:Claim]>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }

    func userInfo(_ request: UserInfo.Request, completion: @escaping (Result<APIResponse<UserInfo>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }

    func keys(_ request: KeysRequest, completion: @escaping (Result<APIResponse<JWKS>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }
}
