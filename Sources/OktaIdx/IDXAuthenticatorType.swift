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

extension Authenticator {
    /// The state this authenticator is currently in.
    public enum State: Comparable {
        case normal, enrolled, authenticating, enrolling, recovery
    }
    
    /// The type of authenticator.
    public enum Kind: Equatable {
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
    public enum Method: Equatable {
        case unknown
        case sms
        case voice
        case email
        case push
        case signedNonce
        case totp
        case otp
        case password
        case webAuthN
        case securityQuestion
        case idp
        case duo
        case federated
    }
}
