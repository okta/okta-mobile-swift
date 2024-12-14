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
import OSLog

// **Note:** It would be preferable to use `Logger` for this, but this would mean setting the minimum OS version to iOS 14.
//
// Since this is a debug feature, It isn't worthwhile to update the minimum supported OS version for just this.
//
// If the minimum supported version of this SDK is to increase in the future, this class should be updated to use the modern Logger struct.

/// Convenience class used for debugging SDK network operations.
public class DebugAPIRequestObserver: OAuth2ClientDelegate {
    /// Shared convenience instance to use.
    public static var shared: DebugAPIRequestObserver = {
        DebugAPIRequestObserver()
    }()
    
    /// Indicates if HTTP request and response headers should be logged.
    public var showHeaders = false

    public func api(client: any APIClient, willSend request: inout URLRequest) {
        var headers = "<omitted>"
        if showHeaders {
            dump(request.allHTTPHeaderFields ?? [:], to: &headers)
        }

        if let bodyData = request.httpBody,
           let body = String(data: bodyData, encoding: .utf8)
        {
            os_log(.debug, log: Self.log, "Sending HTTP Request\nEndpoint: %{public}s %s\nHeaders: %s\nBody: %d bytes\n\n%s",
                   request.httpMethod ?? "<null>",
                   request.url?.absoluteString ?? "<null>",
                   headers,
                   bodyData.count,
                   body)
        } else {
            os_log(.debug, log: Self.log, "Sending HTTP Request\nEndpoint: %{public}s %s\nHeaders: %s",
                   request.httpMethod ?? "<null>",
                   request.url?.absoluteString ?? "<null>",
                   headers)
        }
    }
    
    public func api(client: any APIClient, didSend request: URLRequest, received response: HTTPURLResponse) {
        var headers = "<omitted>"
        if showHeaders {
            dump(response.allHeaderFields, to: &headers)
        }
        
        os_log(.debug, log: Self.log, "Received HTTP Response %{public}s\nStatus Code: %d\nHeaders: %s",
               requestId(from: response.allHeaderFields, using: client.requestIdHeader),
               response.statusCode,
               headers)
    }
    
    public func api(client: any APIClient,
                    didSend request: URLRequest,
                    received error: APIClientError,
                    requestId: String?,
                    rateLimit: APIRateLimit?)
    {
        var result = ""
        dump(error, to: &result)
        os_log(.debug, log: Self.log, "Error:\n%{public}s", result)
    }
    
    public func api<T>(client: any APIClient,
                       didSend request: URLRequest,
                       received response: APIResponse<T>) where T : Decodable
    {
        var result = ""
        dump(response.result, to: &result)
        
        os_log(.debug, log: Self.log, "Response:\n\n%s", result)
    }
    
    private static var log = OSLog(subsystem: "com.okta.client.network", category: "Debugging")
    private func requestId(from headers: [AnyHashable: Any]?, using name: String?) -> String {
        headers?.first(where: { (key, _) in
            (key as? String)?.lowercased() == name?.lowercased()
        })?.value as? String ?? "<unknown>"
    }
}


