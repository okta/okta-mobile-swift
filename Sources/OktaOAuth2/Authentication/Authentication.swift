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

public protocol AuthenticationConfiguration {
    var baseURL: URL { get }
}

public protocol AuthenticationDelegate: AnyObject {
    func authenticationStarted<Flow>(flow: Flow)
    func authenticationFinished<Flow>(flow: Flow)
    func authentication<Flow>(flow: Flow, received token: Token)
    func authentication<Flow>(flow: Flow, received error: OAuth2Error)
}

public protocol AuthenticationFlow: AnyObject, UsesDelegateCollection {
    associatedtype AuthConfiguration where AuthConfiguration: AuthenticationConfiguration

    var configuration: AuthConfiguration { get }
    var isAuthenticating: Bool { get }
    
    func cancel()
    func reset()
}

internal protocol TokenExchangeable {
    var tokenExchangeParameters: [String:String] { get }
}

public struct Authentication {
    public enum Flow {
        case authorizationCode
        case interactionCode
        case clientCredential
        case deviceAuthorization
        case implicit
        case hybrid
        case resourceOwner
    }

    public enum ResponseType: String {
        case token, code
    }
    
    public enum GrantType: String {
        case authorizationCode = "authorization_code"
        case interactionCode = "interaction_code"
        case password
        case clientCredentials = "client_credentials"
        case refreshToken = "refresh_token"
        
        var responseKey: String {
            switch self {
            case .authorizationCode:
                return "code"
            default:
                return rawValue
            }
        }
    }
}
        
