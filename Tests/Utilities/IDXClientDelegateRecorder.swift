/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
import OktaIdx

class DelegateRecorder: IDXClientDelegate {
    struct Call {
        enum CallType {
            case error
            case response
            case token
        }
        
        let type: CallType
        let object: AnyObject?
        let isMainThread: Bool = {
            Thread.isMainThread
        }()
        
        var response: IDXClient.Response? {
            guard let result = object as? IDXClient.Response else { return nil }
            return result
        }

        var token: IDXClient.Token? {
            guard let result = object as? IDXClient.Token else { return nil }
            return result
        }
    }
    
    private(set) var calls: [Call] = []
    
    func reset() {
        calls.removeAll()
    }
    
    func idx(client: IDXClient, didReceive error: Error) {
        calls.append(Call(type: .error, object: nil))
    }
    
    func idx(client: IDXClient, didReceive response: IDXClient.Response) {
        calls.append(Call(type: .response, object: response))
    }
    
    func idx(client: IDXClient, didExchangeToken token: IDXClient.Token) {
        calls.append(Call(type: .token, object: token))
    }
}
