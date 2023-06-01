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
import OktaOAuth2

extension WebAuthentication.Option {
    var queryItems: [String: String] {
        switch self {
        case .login(hint: let username):
            return ["login_hint": username]
        case .display(let value):
            return ["display": value]
        case .idp(url: let url):
            return ["idp": url.absoluteString]
        case .idpScope(let scope):
            return ["idp_scope": scope]
        case .prompt(let value):
            return ["prompt": value.rawValue]
        case .custom(key: let key, value: let value):
            return [key: value]
        case .maxAge, .state:
            return [:]
        }
    }
}

extension Collection where Element == WebAuthentication.Option {
    var additionalParameters: [String: String] {
        map(\.queryItems)
            .reduce([:]) { $0.merging($1) { current, _ in current } }
    }
    
    var state: String? {
        guard case let .state(state) = filter({
            switch $0 {
            case .state:
                return true
            default:
                return false
            }
        }).first else {
            return nil
        }
        
        return state
    }
    
    var maxAge: TimeInterval? {
        guard case let .maxAge(result) = filter({
            switch $0 {
            case .maxAge:
                return true
            default:
                return false
            }
        }).first else {
            return nil
        }
        
        return result
    }
    
    var context: AuthorizationCodeFlow.Context? {
        let state = self.state
        let maxAge = self.maxAge
        
        guard state != nil || maxAge != nil else {
            return nil
        }
        
        return .init(state: state, maxAge: maxAge)
    }
}
