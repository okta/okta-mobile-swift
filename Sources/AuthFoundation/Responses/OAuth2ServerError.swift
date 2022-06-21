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

/// Describes errors reported from an OAuth2 server.
public struct OAuth2ServerError: Decodable, Error, LocalizedError {
    /// Error code.
    public let code: String
    
    /// Error message, or description.
    public let description: String
    
    public var errorDescription: String? { description }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decode(String.self, forKey: .description)
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case code = "error"
        case description = "errorDescription"
    }
}
