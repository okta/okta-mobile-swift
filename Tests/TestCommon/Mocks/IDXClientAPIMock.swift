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

class MockBase {
    struct RecordedCall {
        let function: String
        let arguments: [String:Any]?
    }

    var recordedCalls: [RecordedCall] = []
    func reset() {
        recordedCalls.removeAll()
    }
    
    private(set) var expectations: [String:[String:Any]] = [:]
    func expect(function name: String, arguments: [String:Any]) {
        expectations[name] = arguments
    }
    
    func response(for name: String) -> [String:Any]? {
        return expectations.removeValue(forKey: name)
    }
}

class IDXClientAPIMock: MockBase, IDXClientAPI {
    var context: IDXClient.Context
    
    init(context: IDXClient.Context) {
        self.context = context
    }
    
    func resume(completion: IDXClient.ResponseResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [:]))
        let result = response(for: #function)
        completion?(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func proceed(remediation option: IDXClient.Remediation, completion: IDXClient.ResponseResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                          ]))
        let result = response(for: #function)
        completion?(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func exchangeCode(redirect url: URL, completion: IDXClient.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        let result = self.response(for: #function)
        completion?(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
    
    func exchangeCode(using remediation: IDXClient.Remediation, completion: IDXClient.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "using": response as Any
                                          ]))
        let result = self.response(for: #function)
        completion?(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        
        return .authenticated
    }
}

class IDXClientAPIv1Mock: MockBase, IDXClientAPIImpl {
    var client: IDXClientAPI?
    let configuration: IDXClient.Configuration
    static var version: IDXClient.Version = .latest
    
    init(configuration: IDXClient.Configuration) {
        self.configuration = configuration
    }
    
    func start(state: String?, completion: @escaping (IDXClient.Context?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "state": state as Any
                                          ]))
        let result = response(for: #function)
        completion(result?["context"] as? IDXClient.Context, result?["error"] as? Error)
    }
    
    func resume(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func proceed(remediation option: IDXClient.Remediation, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                          ]))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "url": url as Any
                                          ]))
        let result = response(for: #function)
        return result?["result"] as? IDXClient.RedirectResult ?? .invalidContext
    }
    
    @objc func exchangeCode(redirect url: URL, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }

    func exchangeCode(using remediation: IDXClient.Remediation, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "using": remediation as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
    
    func revoke(token: String, type: String, completion: @escaping (Bool, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "token": token as Any,
                                            "type": type as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["success"] as? Bool ?? true, result?["error"] as? Error)
    }
    
    func refresh(token: IDXClient.Token, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "token": token as Any
                                          ]))
        let result = self.response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
}
