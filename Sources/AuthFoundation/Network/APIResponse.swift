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
    @available(*, deprecated, renamed: "APIRateLimit")
    public typealias RateLimit = APIRateLimit
    
    /// Links between response resources.
    public enum Link: String, Codable {
        case current = "self", next, previous
    }
    
    /// Result provided from the request.
    public let result: T
    
    /// The date the response was received, as reported by the server.
    public let date: Date
    
    /// The actual HTTP status code for the result.
    public let statusCode: Int
    
    /// Information about links between related resources.
    public let links: [Link: URL]
    
    /// Information about the current rate limit.
    public let rateInfo: APIRateLimit?
    
    /// The ID for the current request.
    public let requestId: String?
}

/// Describes an empty server response when a ``APIResponse`` is received without a response body.
public struct Empty: Decodable {}
