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

#if targetEnvironment(simulator) && DEBUG

public class URLSessionAudit: CustomStringConvertible {
    public static let shared = URLSessionAudit()
    internal let queue = DispatchQueue(label: "com.okta.urlsession.audit", qos: .utility)
    public private(set) var logs: [Log] = []
    public var logToConsole = false
    
    public func reset() {
        queue.sync {
            self.logs.removeAll()
        }
    }
    
    internal func add(log item: Log) {
        queue.async {
            self.logs.append(item)

            if self.logToConsole {
                print(item)
            }
        }
    }
    
    public struct Log: CustomStringConvertible {
        let date: Date
        let url: URL?
        let method: String?
        let headers: [AnyHashable:Any]?
        let statusCode: Int?
        let requestBody: Data?
        let responseBody: Data?
        
        init(with request: URLRequest, response: URLResponse?, body data: Data?) {
            date = Date()
            url = request.url
            method = request.httpMethod
            requestBody = request.httpBody
            if let httpResponse = response as? HTTPURLResponse {
                headers = httpResponse.allHeaderFields
                statusCode = httpResponse.statusCode
            } else {
                headers = nil
                statusCode = nil
            }
            responseBody = data
        }

        public var description: String {
            let requestString: String
            if let body = requestBody {
                requestString = String(data: body, encoding: .utf8) ?? "<invalid data>"
            } else {
                requestString = "<no request body>"
            }

            let responseString: String
            if let body = responseBody {
                responseString = String(data: body, encoding: .utf8) ?? "<invalid data>"
            } else {
                responseString = "<no response body>"
            }
            
            let requestId = headers?["x-okta-request-id"] as? String ?? "<null>"
            
            return "\(method ?? "<null>") \(url?.absoluteString ?? "<null>")\nRequest Body:\n\(requestString)\nStatus code: \(statusCode ?? 0)\nRequest ID: \(requestId)\n\(responseString)\n"
        }
    }
    
    public var description: String {
        return logs
            .map { $0.description }
            .joined(separator: "\n")
    }
}

#endif
