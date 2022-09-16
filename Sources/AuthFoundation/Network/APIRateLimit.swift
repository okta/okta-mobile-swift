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

/// Describes information related to the organization's current rate limit.
public struct APIRateLimit: Decodable {
    /// The current limit.
    public let limit: Int
    
    /// The rate limit remaining.
    public let remaining: Int

    /// The time offset from UTC when the rate limit will reset, and a request may be retried.
    public let reset: TimeInterval
    
    /// The calculated delay from the reset limit and the date header.
    public let delay: TimeInterval?
    
    init?(with httpHeaders: [AnyHashable: Any]) {
        guard let rateLimitString = httpHeaders["x-rate-limit-limit"] as? String,
              let rateLimit = Int(rateLimitString),
              let remainingString = httpHeaders["x-rate-limit-remaining"] as? String,
              let remaining = Int(remainingString),
              let resetString = httpHeaders["x-rate-limit-reset"] as? String,
              let reset = TimeInterval(resetString),
              let dateString = httpHeaders["Date"] as? String,
              let date = httpDateFormatter.date(from: dateString)
        else {
            return nil
        }
        
        self.limit = rateLimit
        self.remaining = remaining
        self.reset = reset
        
        if remaining <= 0 {
            let calculatedDelay = reset - date.timeIntervalSince1970
            self.delay = max(calculatedDelay, TimeInterval(1))
        } else {
            self.delay = nil
        }
    }
}
