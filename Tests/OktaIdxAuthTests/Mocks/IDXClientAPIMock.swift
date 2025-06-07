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
@testable import OktaIdxAuth

enum InteractionCodeFlowMockError: Error {
    case noResult(function: String, response: Response?)
    case noResult(function: String, remediation: Remediation?)
    case invalidResultError(_ error: (any Error)?)
}

actor InteractionCodeFlowMock: InteractionCodeFlowAPI, @unchecked Sendable {
    struct RecordedCall: Sendable {
        let function: String
        let arguments: [String: any Sendable]?
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
    
    func result<T>(for name: String) -> Result<T, any Error>? {
        let responseData = response(for: name)
        if let result = responseData?["object"] as? T {
            return .success(result)
        }

        if let error = responseData?["error"] as? (any Error) {
            return .failure(error)
        }
        return nil
    }

    let client: OAuth2Client
    let redirectUri: URL
    let context: InteractionCodeFlow.Context?
    
    init(context: InteractionCodeFlow.Context = .init(), client: OAuth2Client, redirectUri: URL) {
        self.context = context
        self.client = client
        self.redirectUri = redirectUri
    }

    func resume(with response: Response) async throws -> Token {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["response": response]))
        let result: Result<Token, any Error>? = self.result(for: #function)
        switch result {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        default:
            throw InteractionCodeFlowMockError.noResult(function: #function, response: response)
        }
    }

    func resume(with remediation: Remediation) async throws -> Response {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["remediation": remediation]))
        let result: Result<Response, any Error>? = self.result(for: #function)
        switch result {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        default:
            throw InteractionCodeFlowMockError.noResult(function: #function, remediation: remediation)
        }
    }
}
