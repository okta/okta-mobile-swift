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

public enum ClaimError: Error {
    /// The token response is missing a required value.
    case missingRequiredValue(key: String)
}

extension ClaimError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingRequiredValue(key: let key):
            return String.localizedStringWithFormat(
                NSLocalizedString("claim.missing_required_value",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                key)

        }
    }
}
