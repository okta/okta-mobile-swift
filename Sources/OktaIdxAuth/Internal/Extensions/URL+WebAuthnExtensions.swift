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
import AuthFoundation

extension String {
    static func relyingPartyIssuer(from json: JSON, issuerURL: URL) throws -> String {
        // On registration requests, the server-supplied rpId value is within the `rp.id` path.
        if case let .object(rp) = json["rp"],
           case let .string(id) = rp["id"]
        {
            return id
        }

        // On authentication requests, the server-supplied rpId value is in the root `rpId` property.
        if case let .string(id) = json["rpId"] {
            return id
        }

        var hostURL: URL?
        if case let .object(appidParent) = json["u2fParams"],
           case let .string(appid) = appidParent["appid"],
           let appUrl = URL(string: appid)
        {
            hostURL = appUrl
        }

        else if case let .object(appidParent) = json["extensions"],
                case let .string(appid) = appidParent["appid"],
                let appUrl = URL(string: appid)
        {
            hostURL = appUrl
        }

        if let host = hostURL?.host {
            return host
        } else if let host = issuerURL.host {
            return host
        } else {
            throw WebAuthnCapabilityError.missingRelyingPartyIdentifier
        }
    }
}
