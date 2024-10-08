//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension Token {
    /// When refreshing a token, not all values are always returned, especially the refresh token or device secret.
    ///
    /// This function is used to merge these values from an existing token instance to preserve them during a refresh.
    /// - Parameter token: The old token that has been refreshed.
    /// - Returns: A new token merging the results of the newly refreshed token, and the older token.
    func token(merging token: Token) throws -> Token {
        let newPayload = try Token
            .exchangeCoordinator
            .merge(token,
                   payload: token.payload,
                   with: payload)
        
        let oldJSON = jsonPayload.jsonValue
        let newJSON = try JSON(newPayload)
        
        if oldJSON != newJSON {
            return try Token(id: id,
                             issuedAt: issuedAt ?? token.issuedAt ?? .nowCoordinated,
                             context: context,
                             json: .init(newJSON))
        }

        return self
    }
}
