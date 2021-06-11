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

extension IDXClient: IDXClientAPI {
    public func proceed(remediation option: Remediation, completion: ResponseResult?) {
        api.proceed(remediation: option) { (response, error) in
            self.handleResponse(response, error: error, completion: completion)
        }
    }

    public func exchangeCode(using remediation: Remediation, completion: TokenResult?) {
        api.exchangeCode(using: remediation) { (token, error) in
            self.handleResponse(token, error: error, completion: completion)
        }
    }
    
    internal func handleResponse<T>(_ response: T?, error: Error?, completion: ((T?, Error?) -> Void)?) {
        self.informDelegate(self.delegate, response: response, error: error)
        
        completion?(response, error)
    }
    
    internal func informDelegate<T>(_ delegate: IDXClientDelegate?, response: T?, error: Error?) {
        guard let delegate = delegate else { return }
        if let error = error {
            delegate.idx(client: self, didReceive: error)
        }
        
        if let response = response as? Response {
            delegate.idx(client: self, didReceive: response)
        } else if let response = response as? Token {
            delegate.idx(client: self, didReceive: response)
        }
    }
}
