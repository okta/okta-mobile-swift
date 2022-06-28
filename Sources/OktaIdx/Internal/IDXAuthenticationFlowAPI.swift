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
import AuthFoundation

protocol IDXAuthenticationFlowAPI: AnyObject {
    var client: OAuth2Client { get }
    var redirectUri: URL { get }
    var context: IDXAuthenticationFlow.Context? { get }

    func send(response: Response, completion: IDXAuthenticationFlow.ResponseResult?)
    func send(response: Token, completion: IDXAuthenticationFlow.TokenResult?)
    func send(error: IDXAuthenticationFlowError, completion: IDXAuthenticationFlow.ResponseResult?)
    func send(error: IDXAuthenticationFlowError, completion: IDXAuthenticationFlow.TokenResult?)
    func redirectResult(for url: URL) -> IDXAuthenticationFlow.RedirectResult
    func reset()
}

extension IDXAuthenticationFlow: IDXAuthenticationFlowAPI {}
