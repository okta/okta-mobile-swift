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

/// Capability when an authenticator or rememediation contains related profile information.
public struct ProfileCapability: Capability, Sendable, Equatable, Hashable {
    /// Profile information describing the authenticator.
    ///
    /// This usually contains redacted information relevant to display to the user.
    public let values: [String: String]
    
    /// Returns the nested `profile` field with the given name.
    public subscript(name: String) -> String? {
        values[name]
    }
    
    internal init(profile: [String: String]) {
        self.values = profile
    }
}
