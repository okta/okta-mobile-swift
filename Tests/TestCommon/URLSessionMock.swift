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
    
    func dataTaskWithRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let response = call(for: request.url!.absoluteString)
        requests.append(request)
        return URLSessionDataTaskMock(session: self,
                                      data: response?.data,
                                      response: response?.response,
                                      error: response?.error,
                                      completionHandler: completionHandler)
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let response = call(for: request.url!.absoluteString)
        requests.append(request)
        return URLSessionDataTaskMock(session: self,
                                      data: response?.data,
                                      response: response?.response,
                                      error: response?.error,
                                      completionHandler: completionHandler)
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        requests.append(request)

        let response = call(for: request.url!.absoluteString)
        if let error = response?.error {
            throw error
        }
        
        else if let data = response?.data,
                let response = response?.response
        {
            return (data, response)
        }
        
        else {
            throw APIClientError.unknown
        }
    }
    #endif
}

class URLSessionDataTaskMock: URLSessionDataTaskProtocol {
    weak var session: URLSessionMock?
    
    let completionHandler: (Data?, HTTPURLResponse?, Error?) -> Void
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?
    
    init(session: URLSessionMock,
         data: Data?,
         response: HTTPURLResponse?,
         error: Error?,
         completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
    {
        self.session = session
        self.completionHandler = completionHandler
        self.data = data
        self.response = response
        self.error = error
    }
    
    func resume() {
        guard let delay = session?.requestDelay else {
            DispatchQueue.global().async {
                self.completionHandler(self.data, self.response, self.error)
            }
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.completionHandler(self.data, self.response, self.error)
        }
    }
}

