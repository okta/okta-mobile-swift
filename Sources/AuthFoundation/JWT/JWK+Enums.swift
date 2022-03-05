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

extension JWK {
    public enum KeyType: String, Codable {
        case ellipticCurve = "EC"
        case rsa = "RSA"
        case octetSequence = "oct"
    }
    
    public enum Usage: String, Codable {
        case signature = "sig"
        case encryption = "enc"
    }

    public enum Algorithm: String, Codable {
        case hs256 = "HS256"
        case hs384 = "HS384"
        case hs512 = "HS512"
        case rs256 = "RS256"
        case rs384 = "RS384"
        case rs512 = "RS512"
        case es256 = "ES256"
        case es384 = "ES384"
        case es512 = "ES512"
    }
}
