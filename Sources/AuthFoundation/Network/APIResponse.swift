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

/// Describes a response from an Okta request, which includes the supplied result, and other associated response metadata.
public struct APIResponse<T: Decodable>: Decodable {
    /// Links between response resources.
    public enum Link: String, Codable {
        case current = "self", next, previous
    }
    
    /// Result provided from the request.
    public let result: T
    
    /// The date the response was received, as reported by the server.
    public let date: Date
    
    /// Information about links between related resources.
    public let links: [Link:URL]
    
    /// Information about the current rate limit.
    public let rateInfo: RateLimit?
    
    /// The ID for the current request.
    public let requestId: String?
    
    /// Describes information related to the organization's current rate limit.
    public struct RateLimit: Decodable {
        /// The current limit.
        public let limit: Int
        
        /// The rate limit remaining.
        public let remaining: Int

        /// The time offset from UTC when the rate limit will reset, and a request may be retried.
        public let reset: TimeInterval
        
        init?(with httpHeaders: [AnyHashable:Any]) {
            guard let rateLimitString = httpHeaders["x-rate-limit-limit"] as? String,
                  let rateLimit = Int(rateLimitString),
                  let remainingString = httpHeaders["x-rate-limit-remaining"] as? String,
                  let remaining = Int(remainingString),
                  let resetString = httpHeaders["x-rate-limit-reset"] as? String,
                  let reset = TimeInterval(resetString)
            else {
                return nil
            }
            
            self.limit = rateLimit
            self.remaining = remaining
            self.reset = reset
        }
    }
    
}

/// Describes an empty server response when a ``APIResponse`` is received without a response body.
public struct Empty: Decodable {}
