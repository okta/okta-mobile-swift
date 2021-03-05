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
@testable import OktaIdx

class IDXClientAPIv1Mock: IDXClientAPIImpl {
    
    var client: IDXClientAPI?
    
    var canCancel: Bool {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        return false
    }
    
    let configuration: IDXClient.Configuration
    
    struct RecordedCall {
        let function: String
        let arguments: [String:Any]?
    }
    static var version = IDXClient.Version.v1_0_0
    var recordedCalls: [RecordedCall] = []
    func reset() {
        recordedCalls.removeAll()
    }
    
    private var expectations: [String:[String:Any]] = [:]
    func expect(function name: String, arguments: [String:Any]) {
        expectations[name] = arguments
    }
    
    private func response(for name: String) -> [String:Any]? {
        return expectations.removeValue(forKey: name)
    }
    
    init(configuration: IDXClient.Configuration) {
        self.configuration = configuration
    }
    
    func interact(state: String?, completion: @escaping (IDXClient.Context?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["context"] as? IDXClient.Context, result?["error"] as? Error)
    }
    
    func introspect(_ context: IDXClient.Context, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func cancel(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func proceed(remediation option: IDXClient.Remediation.Option, data: [String : Any], completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                            "data": data 
                                          ]))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func redirectResult(with context: IDXClient.Context, redirect url: URL) -> IDXClient.RedirectResult {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "context": context as Any,
                                            "redirect": url as Any
                                          ]))
        
        return client?.redirectResult(with: context, redirect: url) ?? .invalidContext
    }
    
    @objc func exchangeCode(with context: IDXClient.Context, redirect url: URL, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "with": context as Any,
                                            "redirect": url as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }

    func exchangeCode(with context: IDXClient.Context, using response: IDXClient.Response, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "with": context as Any,
                                            "using": response as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
}
