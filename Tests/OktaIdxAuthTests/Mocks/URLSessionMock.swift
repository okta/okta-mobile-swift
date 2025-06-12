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
import XCTest

@testable import AuthFoundation
@testable import OktaIdxAuth

#if os(Linux)
import FoundationNetworking
#endif

extension Response {
    class func response(flow: any InteractionCodeFlowAPI,
                        data: Data) throws -> Response
    {
        do {
            let response = try InteractionCodeFlow.IntrospectRequest.jsonDecoder.decode(IonResponse.self, from: data)
            return try Response(flow: flow, ion: response)
        } catch {
            print("Error decoding JSON: \(error)")
            throw error
        }
    }
}

class URLSessionMock: URLSessionProtocol, @unchecked Sendable {
    var configuration: URLSessionConfiguration = .ephemeral
    let queue = DispatchQueue(label: "URLSessionMock")
    private let lock = Lock()

    struct Call {
        let url: String
        let data: Data?
        let response: HTTPURLResponse?
        let error: (any Error)?
    }

    var requestDelay: TimeInterval?

    private var _requests: [URLRequest] = []
    private(set) var requests: [URLRequest] {
        get {
            lock.withLock {
                _requests
            }
        }
        set {
            lock.withLock {
                _requests = newValue
            }
        }
    }

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
                headerFields: [String: String]? = nil,
                error: (any Error)? = nil)
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
                    try await Task.sleep(delay: delay)
                }

                guard let data = call?.data,
                      let response = call?.response
                else {
                    if let error = call?.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: APIClientError.missingResponse(request: request))
                    }
                    return
                }

                continuation.resume(returning: (data, response))
            }
        }
    }
}
