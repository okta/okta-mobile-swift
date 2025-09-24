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
import CommonSupport

#if canImport(Security)
#if compiler(<6.0)
import Security
#else
@preconcurrency import Security
#endif
#endif

#if canImport(LocalAuthentication) && !os(tvOS)
#if compiler(<6.0)
import LocalAuthentication

extension SecAccessControl: @unchecked Sendable {}
#else
@preconcurrency import LocalAuthentication
#endif
#endif

extension Credential {
    /// Defines the security options that are applicable to individual credentials.
    ///
    /// When storing credentials, you can supply a list of customizations you would like to use to indicate the security accessibility settings of that item. For example, you can indicate biometric or user presence for items.
    ///
    /// On Apple platforms, this controls the Keychain security settings for the underlying token's keychain item.
    public enum Security: Sendable {
        #if canImport(Darwin)
        /// Defines the accessibility level for a credential.
        case accessibility(_ option: Keychain.Accessibility)
        
        /// Defines custom access control flags, such as requiring user presense or a device passcode.
        case accessControl(_ flags: SecAccessControlCreateFlags)

        /// Defines access control settings, using a predefined `SecAccessControl` value.
        case accessControlRef(_ secRef: SecAccessControl)
        
        /// Assigns a custom access group for this credential.
        case accessGroup(_ name: String)

        #if canImport(LocalAuthentication) && !os(tvOS)
        /// Defines a custom LocalAuthentication context for interactions with this credential, for systems that support it.
        case context(_ obj: LAContext)
        #endif
        #endif

        /// The standard set of security settings to use when creating or getting credentials.
        ///
        /// If you wish to change the default security threshold for Keychain items, you can assign a new value here. Additionally, if a ``context(_:)`` value is assigned to the ``standard`` property, that context will be used when fetching credentials unless otherwise specified.
        public static var standard: [Security] {
            get {
                lock.withLock { _standard }
            }
            set {
                lock.withLock { _standard = newValue }
            }
        }

        /// Determines whether or not the ``Credential/default`` setting is synchronized across a user's devices using iCloud Keychain.
        public static var isDefaultSynchronizable: Bool {
            get {
                lock.withLock { _isDefaultSynchronizable }
            }
            set {
                lock.withLock { _isDefaultSynchronizable = newValue }
            }
        }

        // MARK: Private properties / methods
        private static let lock = Lock()
        nonisolated(unsafe) private static var _isDefaultSynchronizable: Bool = false

        #if canImport(Darwin)
        nonisolated(unsafe) private static var _standard: [Security] = [
            .accessibility(.afterFirstUnlockThisDeviceOnly)
        ]
        #else
        nonisolated(unsafe) private static var _standard: [Security] = []
        #endif
    }
}
