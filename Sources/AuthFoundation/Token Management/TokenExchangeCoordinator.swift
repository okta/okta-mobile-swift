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

protocol TokenExchangeCoordinator {
    /// When refreshing a token, not all values are always returned, especially the refresh token or device secret.
    ///
    /// This function is used to merge these values from an existing token instance to preserve them during a refresh.
    /// - Parameters:
    ///   - token: The token into which a new response is being merged.
    ///   - payload: The current token payload.
    ///   - newPayload: The new token payload to be merged.
    /// - Returns: The payload for the token by merging the old values with the new ones.
    func merge(_ token: Token, payload: [String: Any], with newPayload: [String: Any]) throws -> [String: Any]
}
