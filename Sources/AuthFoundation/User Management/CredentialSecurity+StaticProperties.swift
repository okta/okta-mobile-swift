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

fileprivate let staticLock = Lock()
nonisolated(unsafe) fileprivate var _isDefaultSynchronizable: Bool = false

#if canImport(Darwin)
nonisolated(unsafe) fileprivate var _standard: [Credential.Security] = [.accessibility(.afterFirstUnlockThisDeviceOnly)]
#else
nonisolated(unsafe) fileprivate var _standard: [Credential.Security] = []
#endif

extension Credential.Security {
    /// The standard set of security settings to use when creating or getting credentials.
    ///
    /// If you wish to change the default security threshold for Keychain items, you can assign a new value here. Additionally, if a ``context(_:)`` value is assigned to the ``standard`` property, that context will be used when fetching credentials unless otherwise specified.
    @Synchronized(variable: _standard, lock: staticLock)
    public static var standard: [Credential.Security]
    
    /// Determines whether or not the ``Credential/default`` setting is synchronized across a user's devices using iCloud Keychain.
    @Synchronized(variable: _isDefaultSynchronizable, lock: staticLock)
    public static var isDefaultSynchronizable: Bool
}
