//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import XCTest

#if os(Linux)
import FoundationNetworking
#endif

@testable import AuthFoundation

class URLSessionMock: URLSessionProtocol {
    var configuration: URLSessionConfiguration = .ephemeral
    let queue = DispatchQueue(label: "URLSessionMock")
    
    struct Call {
        let url: String
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }
    
    var requestDelay: TimeInterval?

    private(set) var requests: [URLRequest] = []
    func resetRequests() {
        requests.removeAll()
    }

    private(set) var expectedCalls: [Call] = []
    func expect(call: Call) {
        queue.sync {
            expectedCalls.append(call)
        }
    }
    
    func request(matching string: String) -> URLRequest? {
        requests.first(where: { $0.url?.absoluteString.localizedCaseInsensitiveContains(string) ?? false })
    }
    
    func formDecodedBody(matching string: String) -> [String: String?]? {
        request(matching: string)?.httpBody?.urlFormEncoded
    }
    
    func expect(_ url: String,
                data: Data?,
                statusCode: Int = 200,
                contentType: String = "application/x-www-form-urlencoded",
                headerFields: [String : String]? = nil,
                error: Error? = nil)
    {
        let headerFields = ["Content-Type": contentType].merging(headerFields ?? [:]){ (_, new) in new }
        let response = HTTPURLResponse(url: URL(string: url)!,
                                       statusCode: statusCode,
                                       httpVersion: "http/1.1",
                                       headerFields: headerFields)
        
        expect(call: Call(url: url,
                          data: data,
                          response: response,
                          error: error))
    }

    func call(for url: String) -> Call? {
        queue.sync {
            guard let index = expectedCalls.firstIndex(where: { call in
                call.url == url
            }) else {
                XCTFail("Mock URL \(url) not found")
                return nil
            }
            
            return expectedCalls.remove(at: index)
        }
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let call = call(for: request.url!.absoluteString)
        requests.append(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                if let delay = requestDelay {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                guard let data = call?.data,
                      let response = call?.response
                else {
                    if let error = call?.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: APIClientError.missingResponse)
                    }
                    return
                }

                continuation.resume(returning: (data, response))
            }
        }
    }
}
