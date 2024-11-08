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

/// Defines the information for an app or library target.
public struct TargetInformation: CustomStringConvertible, Equatable, Hashable, Codable, Sendable {
    /// The name of the target.
    public let name: String
    
    /// The target's version number.
    public let version: Version?
    
    public var description: String {
        if let version = version {
            return "\(name)/\(version)"
        } else {
            return name
        }
    }
    
    public init(name: String, version: Version?) {
        self.name = name
        self.version = version
    }
}
