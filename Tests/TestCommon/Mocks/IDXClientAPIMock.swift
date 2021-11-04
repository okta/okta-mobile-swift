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
    
    func result<T>(for name: String) -> Result<T, IDXClientError> {
        let responseData = response(for: name)
        if let result = responseData?["response"] as? T {
            return .success(result)
        }
        
        let error = responseData?["error"] as? IDXClientError ?? IDXClientError.invalidClient
        return .failure(error)
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
        completion?(result(for: #function))
    }
    
    func proceed(remediation option: IDXClient.Remediation, completion: IDXClient.ResponseResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                          ]))
        completion?(result(for: #function))
    }
    
    func exchangeCode(redirect url: URL, completion: IDXClient.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        completion?(result(for: #function))
    }
    
    func exchangeCode(using remediation: IDXClient.Remediation, completion: IDXClient.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "using": response as Any
                                          ]))
        completion?(result(for: #function))
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
    
    func start(state: String?, completion: @escaping (Result<IDXClient.Context, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "state": state as Any
                                          ]))
        completion(result(for: #function))
    }
    
    func resume(completion: @escaping (Result<IDXClient.Response, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        completion(result(for: #function))
    }
    
    func proceed(remediation option: IDXClient.Remediation, completion: @escaping (Result<IDXClient.Response, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                          ]))
        completion(result(for: #function))
    }
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "url": url as Any
                                          ]))
        let result = response(for: #function)
        return result?["result"] as? IDXClient.RedirectResult ?? .invalidContext
    }
    
    func exchangeCode(redirect url: URL, completion: @escaping (Result<IDXClient.Token, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        completion(result(for: #function))
    }

    func exchangeCode(using remediation: IDXClient.Remediation, completion: @escaping (Result<IDXClient.Token, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "using": remediation as Any
                                          ]))
        completion(result(for: #function))
    }

    func revoke(token: String, type: String, completion: @escaping (Result<Void, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "token": token as Any,
                                            "type": type as Any
                                          ]))
        completion(result(for: #function))
    }
    
    func refresh(token: IDXClient.Token, completion: @escaping (Result<IDXClient.Token, IDXClientError>) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "token": token as Any
                                          ]))
        completion(result(for: #function))
    }
}
