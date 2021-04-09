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

protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, HTTPURLResponse?, Error?) -> Void
    func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: { (data, response, error) in
            #if targetEnvironment(simulator) && DEBUG
            URLSessionAudit.shared.add(log: .init(with: request, response: response, body: data))
            #endif
            
            self.handleDataTaskRequest(data: data,
                                       response: response,
                                       error: error,
                                       completionHandler: completionHandler)
        }) as URLSessionDataTaskProtocol
    }
    
    internal func handleDataTaskRequest(data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping DataTaskResult) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(data, nil, IDXClientError.invalidHTTPResponse)
            return
        }
        
        guard error == nil else {
            completionHandler(data, httpResponse, error)
            return
        }
        
        guard httpResponse.statusCode < 500 else {
            completionHandler(data, httpResponse, IDXClientError.invalidHTTPResponse)
            return
        }

        completionHandler(data, httpResponse, nil)
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLRequest {
    static func idxURLFormEncodedString(for params: [String:String]) -> String? {
        func escape(_ str: String) -> String {
            return str.replacingOccurrences(of: "\n", with: "\r\n")
                .addingPercentEncoding(withAllowedCharacters: idxQueryCharacters)!
                .replacingOccurrences(of: " ", with: "+")
        }

        return params.keys.sorted().compactMap {
            escape($0) + "=" + escape(params[$0]!)
        }.joined(separator: "&")
    }
    
    private static let idxQueryCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(" ")
        allowed.remove("+")
        allowed.remove("/")
        allowed.remove("&")
        allowed.remove("=")
        allowed.remove("?")
        return allowed
    }()
}
