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

public protocol JWTClaim {}

public struct JWT {
    let header: [String: Any]
    let body: [String: JWTClaim]
    let signature: String?
    let string: String

    let expiresAt: Date?
    let issuer: String?
    let subject: String?
    let audience: [String]?
    let issuedAt: Date?
    let notBefore: Date?
    let identifier: String?

    var expired: Bool {
        false
    }
    
    func claim<T>(_ name: String, with type: T.Type) -> T? where T: JWTClaim {
        body[name] as? T
    }
}

extension String: JWTClaim {}
extension Bool: JWTClaim {}
extension Double: JWTClaim {}
extension Int: JWTClaim {}
extension Date: JWTClaim {}
extension Array: JWTClaim where Element == String {}
