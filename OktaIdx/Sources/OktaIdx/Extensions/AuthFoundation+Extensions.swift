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

extension GrantType {
    public static let interactionCode = GrantType.other("interaction_code")
}

extension APIContentType {
    public static let ionJson = APIContentType.other("application/ion+json; okta-version=1.0.0")
}

extension OAuth2ServerError.Code {
    public static let interactionRequired = OAuth2ServerError.Code(rawValue: "interaction_required")
}
