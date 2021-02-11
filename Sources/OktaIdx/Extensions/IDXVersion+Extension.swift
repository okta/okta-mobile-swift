/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension IDXClient.Version: RawRepresentable {
    /// References the latest version of the SDK
    public static let latest = v1_0_0

    public typealias RawValue = String
    public var rawValue: RawValue {
        switch self {
            case .v1_0_0:
                return "1.0.0"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
            case "1.0.0":
                self = .v1_0_0
            default:
                return nil
        }
    }
}
