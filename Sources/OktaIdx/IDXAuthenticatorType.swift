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

extension IDXClient.Authenticator {
    @objc(IDXAuthenticatorState)
    public enum State: Int {
        case normal, enrolled, authenticating, enrolling, recovery
    }
    
    /// The type of authenticator.
    @objc(IDXAuthenticatorKind)
    public enum Kind: Int {
        case unknown
        case app
        case email
        case phone
        case password
        case securityQuestion
        case device
        case securityKey
        case federated
    }
    
    /// The method, or sub-type, of an authenticator.
    @objc(IDXAuthenticatorMethod)
    public enum Method: Int {
        case unknown
        case sms
        case voice
        case email
        case push
        case crypto
        case signedNonce
        case totp
        case password
        case webAuthN
        case securityQuestion
    }
}
