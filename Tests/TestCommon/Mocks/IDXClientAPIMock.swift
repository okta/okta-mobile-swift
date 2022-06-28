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
    
    func result<T>(for name: String) -> Result<T, InteractionCodeFlowError> {
        let responseData = response(for: name)
        if let result = responseData?["response"] as? T {
            return .success(result)
        }
        
        let error = responseData?["error"] as? InteractionCodeFlowError ?? InteractionCodeFlowError.invalidFlow
        return .failure(error)
    }
}

class InteractionCodeFlowMock: MockBase, InteractionCodeFlowAPI {
    let client: OAuth2Client
    let redirectUri: URL
    let context: InteractionCodeFlow.Context?
    
    init(context: InteractionCodeFlow.Context, client: OAuth2Client, redirectUri: URL) {
        self.context = context
        self.client = client
        self.redirectUri = redirectUri
    }

    func send(response: Response, completion: InteractionCodeFlow.ResponseResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["response": response as Any]))
        completion?(result(for: #function))
    }
    
    func send(response: Token, completion: InteractionCodeFlow.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["response": response as Any]))
        completion?(result(for: #function))
    }
    
    func send(error: InteractionCodeFlowError, completion: InteractionCodeFlow.ResponseResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["error": error as Any]))
        completion?(result(for: #function))
    }
    
    func send(error: InteractionCodeFlowError, completion: InteractionCodeFlow.TokenResult?) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["error": error as Any]))
        completion?(result(for: #function))
    }
    
    func redirectResult(for url: URL) -> InteractionCodeFlow.RedirectResult {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "redirect": url as Any
                                          ]))
        
        return .authenticated
    }
}
