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

public enum TokenError: Error {
    case contextMissing
    case tokenNotFound(id: String)
    case cannotReplaceToken
    case duplicateTokenAdded
}

#if SWIFT_PACKAGE
extension TokenError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .contextMissing:
            return NSLocalizedString("token_context_missing",
                                     bundle: .module,
                                     comment: "")
            
        case .tokenNotFound(id: let id):
            return String.localizedStringWithFormat(
                NSLocalizedString("token_not_found",
                                  bundle: .module,
                                  comment: ""),
                id)
            
        case .cannotReplaceToken:
            return NSLocalizedString("cannot_replace_token",
                                     bundle: .module,
                                     comment: "")
            
        case .duplicateTokenAdded:
            return NSLocalizedString("duplicate_token_added",
                                     bundle: .module,
                                     comment: "")
        }
    }
}
#endif
