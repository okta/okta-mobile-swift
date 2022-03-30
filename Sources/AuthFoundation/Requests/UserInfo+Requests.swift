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

extension UserInfo {
    struct Request {
        let openIdConfiguration: OpenIdConfiguration
        let token: Token
    }
}

extension UserInfo.Request: APIRequest, OAuth2APIRequest {
    typealias ResponseType = UserInfo
    
    var httpMethod: APIRequestMethod { .get }
    var url: URL { openIdConfiguration.userinfoEndpoint }
    var acceptsType: APIContentType? { .json }
    var authorization: APIAuthorization? { token }
}
