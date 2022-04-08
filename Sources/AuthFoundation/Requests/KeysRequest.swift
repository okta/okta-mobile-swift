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

#if os(Linux)
import FoundationNetworking
#endif

extension OAuth2Client {
    struct KeysRequest {
        let openIdConfiguration: OpenIdConfiguration
        let clientId: String?
    }
}

extension OAuth2Client.KeysRequest: OAuth2APIRequest {
    typealias ResponseType = JWKS
    
    var httpMethod: APIRequestMethod { .get }
    var url: URL { openIdConfiguration.jwksUri }
    var acceptsType: APIContentType? { .json }
    var query: [String: APIRequestArgument?]? {
        [ "client_id": clientId ]
    }
    var cachePolicy: URLRequest.CachePolicy { .returnCacheDataElseLoad }
}
