//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import CommonSupport
import AuthFoundation
import OpenAPIRuntime
import HTTPTypes

public enum MyAccccountError: Error {
    case decodingError
    case unimplemented
    case invalidHTTPRequest
    case invalidHTTPResponse
}

public final class MyAccount {
    private let lock = Lock()
    public let credential: Credential

    nonisolated(unsafe) private var _client: Client?
    public var client: Client {
        get throws {
            lock.withLock {
                if let _client {
                    return _client
                }
                
                let client = Client(serverURL: credential.oauth2.baseURL,
                                    transport: self)
                _client = client
                return client
            }
        }
    }
    
    public init(credential: Credential) {
        self.credential = credential
    }
}

extension MyAccount: ClientTransport {
    public func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
        guard let url = request.url else {
            throw MyAccccountError.invalidHTTPRequest
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = try await body?.data
        
        await credential.authorize(&urlRequest)
        
        let (data, response) = try await credential.oauth2.session.data(for: urlRequest)
        guard let httpResponse = HTTPResponse(response: response) else {
            throw MyAccccountError.invalidHTTPResponse
        }
        return (httpResponse, HTTPBody(data: data))
    }
}

func foo(myaccount: MyAccount) async throws {
    let result = try await myaccount.email.create("foo@example.com")
//    try await myaccount.phone.create("foo", sendCode: true, method: .call
    
//    print(try await myaccount.organization.name)
}
