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

/// Describes errors that may be reported from an Okta API endpoint.
public struct OktaAPIError: Decodable, Error, LocalizedError, Equatable {
    /// An Okta code for this type of error.
    public let code: String
    
    /// A short description of what caused this error. Sometimes this contains dynamically-generated information about your specific error.
    public let summary: String
    
    /// An Okta code for this type of error
    public let link: String
    
    /// A unique identifier for this error. This can be used by Okta Support to help with troubleshooting.
    public let id: String
    
    /// Further information about what caused this error.
    public let causes: [String]
    
    public var errorDescription: String? { summary }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        summary = try container.decode(String.self, forKey: .summary)
        link = try container.decode(String.self, forKey: .link)
        id = try container.decode(String.self, forKey: .id)
        causes = try container.decode([String].self, forKey: .causes)
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case code = "errorCode"
        case summary = "errorSummary"
        case link = "errorLink"
        case id = "errorId"
        case causes = "errorCauses"
    }
}
