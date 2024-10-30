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
import OktaConcurrency
import OktaConcurrency
import JWT

fileprivate let staticLock = Lock()
nonisolated(unsafe) fileprivate var _idTokenValidator: any IDTokenValidator = DefaultIDTokenValidator()
nonisolated(unsafe) fileprivate var _accessTokenValidator: any TokenHashValidator = DefaultTokenHashValidator(hashKey: .accessToken)
nonisolated(unsafe) fileprivate var _deviceSecretValidator: any TokenHashValidator = DefaultTokenHashValidator(hashKey: .deviceSecret)
nonisolated(unsafe) fileprivate var _exchangeCoordinator: any TokenExchangeCoordinator = DefaultTokenExchangeCoordinator()

extension Token {
    /// The object used to ensure ID tokens are valid.
    @Synchronized(variable: _idTokenValidator, lock: staticLock)
    public static var idTokenValidator: any IDTokenValidator
    
    /// The object used to ensure access tokens can be validated against its associated ID token.
    @Synchronized(variable: _accessTokenValidator, lock: staticLock)
    public static var accessTokenValidator: any TokenHashValidator
    
    /// The object used to ensure device secrets are validated against its associated ID token.
    @Synchronized(variable: _deviceSecretValidator, lock: staticLock)
    public static var deviceSecretValidator: any TokenHashValidator
    
    /// Coordinates important operations during token exchange.
    ///
    /// > Note: This property and interface is currently marked as internal, but may be exposed publicly in the future.
    @Synchronized(variable: _exchangeCoordinator, lock: staticLock)
    static var exchangeCoordinator: any TokenExchangeCoordinator
}
