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
import AuthFoundation
import OktaIdx

class DelegateRecorder: InteractionCodeFlowDelegate {
    struct Call {
        enum CallType {
            case error
            case context
            case response
            case token
        }
        
        let type: CallType
        let object: AnyObject?
        
        var response: Response? {
            guard let result = object as? Response else { return nil }
            return result
        }

        var token: Token? {
            guard let result = object as? Token else { return nil }
            return result
        }
    }
    
    private(set) var calls: [Call] = []
    
    private(set) var startCalled: Bool = false
    private(set) var finishedCalled: Bool = false

    func reset() {
        calls.removeAll()
        startCalled = false
        finishedCalled = false
    }
    
    func authenticationStarted<Flow>(flow: Flow) {
        startCalled = true
    }
    
    func authenticationFinished<Flow>(flow: Flow) {
        finishedCalled = true
    }
    
    func authentication<Flow>(flow: Flow, received error: InteractionCodeFlowError) {
        calls.append(Call(type: .error, object: nil))
    }
    
    func authentication<Flow>(flow: Flow, received response: Response) {
        calls.append(Call(type: .response, object: response))
    }
    
    func authentication<Flow>(flow: Flow, received token: Token) {
        calls.append(Call(type: .token, object: token))
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
    }
}
