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
import AuthFoundation

extension URL {
    enum InteractionCodeResult: Equatable {
        case code(String)
        case interactionRequired

        @inlinable
        static func == (lhs: URL.InteractionCodeResult, rhs: URL.InteractionCodeResult) -> Bool {
            switch (lhs, rhs) {
            case (.code(let lhsCode), .code(let rhsCode)):
                return lhsCode == rhsCode
            case (.interactionRequired, .interactionRequired):
                return true
            default:
                return false
            }
        }
    }

    func interactionCode(redirectUri: URL,
                         state: String) throws -> InteractionCodeResult
    {
        do {
            let query = try self.queryValues(matching: redirectUri)
            if let error = try OAuth2ServerError(from: query) {
                throw error
            }

            guard query["state"] == state else {
                throw OAuth2Error.redirectUri(self, reason: .state(query["state"]))
            }

            guard let code = query["interaction_code"] else {
                throw OAuth2Error.redirectUri(self, reason: .codeRequired)
            }

            return .code(code)
        } catch let error as OAuth2ServerError {
            if error.code == .interactionRequired {
                return .interactionRequired
            } else {
                throw error
            }
        } catch {
            throw error
        }
    }
}
