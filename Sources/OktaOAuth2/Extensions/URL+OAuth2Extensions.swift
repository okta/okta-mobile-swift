//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import AuthFoundation

extension URL {
    /// Convenience function to return an authorization code from the given URL.
    /// - Parameters:
    ///   - redirectUri: Redirect URI to match against.
    ///   - state: State token to match against.
    ///   - configuration: OAuth2 client configuration to validate.
    /// - Returns: The authorization code for the given URI.
    public func authorizationCode(state: String,
                                  configuration: OAuth2Client.Configuration?) throws -> String
    {
        let query = try queryValues(matching: configuration?.redirectUri)
        if let error = try OAuth2ServerError(from: query) {
            throw error
        }

        guard query["state"] == state else {
            throw OAuth2Error.redirectUri(self, reason: .state(query["state"]))
        }
        
        guard let code = query["code"] else {
            throw OAuth2Error.redirectUri(self, reason: .codeRequired)
        }
        
        return code
    }
}
