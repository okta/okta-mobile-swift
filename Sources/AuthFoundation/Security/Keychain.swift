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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

#if canImport(LocalAuthentication) && !os(tvOS)
import LocalAuthentication
extension LAContext: KeychainAuthenticationContext {}
#endif

public protocol KeychainAuthenticationContext {}

/// Defines convenience mechanisms for interacting with the keychain, including searching, creating, and deleting keychain items.
///
/// This struct represents a collection of similar objects that can be used to represent keychain items, searches, and search results, with the goal of simplifying keychain operations in a more expressive way.
///
/// > Note: At this time, only Generic Password items are supported by this struct.
public struct Keychain {
    static var implementation: KeychainProtocol = KeychainImpl()
    
    /// Defines an individual keychain item. This may be created using the designated initializer for the purposes of saving a new keychain item, or may be created as the result of getting a preexisting item from the keychain.
    public struct Item: Equatable {
        /// The account (also known as the key, or account ID) for this keychain item.
        public let account: String
        
        /// The service name this account is associated with.
        public let service: String?
        
        /// The server this account is associated with.
        public let server: String?
        
        /// The accessibility level for this keychain item.
        public var accessibility: Accessibility?
        
        /// Indicates whether or not this keychain item may be synchronized to iCloud Keychain.
        public var synchronizable: Bool?
        
        /// The access group this keychain item is stored within.
        public var accessGroup: String?
        
        /// The access control settings for this item.
        public var accessControl: SecAccessControl?
        
        /// The human-readable summary for this keychain item.
        public var label: String?
        
        /// The human-readable description for this keychain item.
        public var description: String?
        
        /// The generic, publicly-visible, data associated with this keychain item.
        public var generic: Data?
        
        /// The secret / private stored within this keychain item.
        public var value: Data
        
        /// Saves the item to the keychain.
        /// - Parameter authenticationContext: Optional `LAContext` to use when saving the credential, for platforms that support it.
        /// - Returns: A ``Keychain/Item`` representing the new saved item.
        @discardableResult
        public func save(authenticationContext: KeychainAuthenticationContext? = nil) throws -> Item {
            var cfDictionary = query
            cfDictionary[kSecReturnAttributes as String] = kCFBooleanTrue
            cfDictionary[kSecReturnData as String] = kCFBooleanTrue
            cfDictionary[kSecReturnRef as String] = kCFBooleanTrue
            
            if let authenticationContext = authenticationContext {
                cfDictionary[kSecUseAuthenticationContext as String] = authenticationContext
            }
            
            if let accessControl = accessControl {
                cfDictionary[kSecAttrAccessControl as String] = accessControl
                cfDictionary.removeValue(forKey: kSecAttrAccessible as String)
            }

            Keychain.implementation.deleteItem(cfDictionary as CFDictionary)
            
            var ref: AnyObject?
            let status = Keychain.implementation.addItem(cfDictionary as CFDictionary, &ref)
            if status != noErr {
                throw KeychainError.cannotSave(code: status)
            }
            
            guard let result = ref as? [String: Any] else {
                throw KeychainError.invalidFormat
            }
            
            return try Item(result)
        }
        
        /// Updates the keychain item with the values supplied in the included item.
        /// - Parameters:
        ///   - item: Item whose values should replace the receiver's keychain item.
        ///   - authenticationContext: Optional `LAContext` to use when updating the item, on platforms that support it.
        public func update(_ item: Keychain.Item, authenticationContext: KeychainAuthenticationContext? = nil) throws {
            try performUpdate(item, authenticationContext: authenticationContext)
        }
        
        /// Deletes this keychain item.
        public func delete() throws {
            try performDelete()
        }
        
        /// Designated initializer, used for creating a new keychain item.
        /// - Parameters:
        ///   - account: The account ID or key to use for this item.
        ///   - service: The service to group similar items together.
        ///   - accessibility: Defines when the item may be retrieved, based on device state.
        ///   - accessGroup: The access group to store this item within.
        ///   - synchronizable: Indicates if this keychain item may be synchronized to iCloud Keychain.
        ///   - label: The human-readable label to summarize this item.
        ///   - description: The human-readable description to add notes related to this item.
        ///   - generic: Generic data associated with this item, which may always be read and is not restricted by the ``accessibility`` option.
        ///   - valueData: The secret value for this item.
        public init(account: String,
                    service: String? = nil,
                    server: String? = nil,
                    accessibility: Accessibility? = .unlocked,
                    accessGroup: String? = nil,
                    accessControl: SecAccessControl? = nil,
                    synchronizable: Bool? = nil,
                    label: String? = nil,
                    description: String? = nil,
                    generic: Data? = nil,
                    value: Data)
        {
            self.account = account
            self.service = service
            self.server = server
            self.accessibility = accessibility
            self.accessGroup = accessGroup
            self.accessControl = accessControl
            self.synchronizable = synchronizable
            self.label = label
            self.description = description
            self.generic = generic
            self.value = value
        }

        init(_ result: [String: Any]) throws {
            guard let account = result[kSecAttrAccount as String] as? String else {
                throw KeychainError.missingAccount
            }
            
            guard let value = result[kSecValueData as String] as? Data else {
                throw KeychainError.missingValueData
            }
            
            guard let accessibilityString = result[kSecAttrAccessible as String] as? String,
                  let accessibility = Keychain.Accessibility(rawValue: accessibilityString)
            else {
                throw KeychainError.invalidAccessibilityOption
            }

            self.account = account
            self.value = value
            self.accessibility = accessibility

            service = result[kSecAttrService as String] as? String
            server = result[kSecAttrServer as String] as? String
            accessGroup = result[kSecAttrAccessGroup as String] as? String
            label = result[kSecAttrLabel as String] as? String
            description = result[kSecAttrDescription as String] as? String
            generic = result[kSecAttrGeneric as String] as? Data
            synchronizable = result[kSecAttrSynchronizable as String] as? Bool

            if let value = result[kSecAttrAccessControl as String] {
                // swiftlint:disable force_cast
                accessControl = (value as! SecAccessControl)
                // swiftlint:enable force_cast
            }
        }
    }
    
    /// Defines the accessibility level for keychain items.
    ///
    /// This is a convenience wrapper around the iOS `kSecAttrAccessible*` Core Foundation strings.
    public enum Accessibility {
        /// Requires the device to be actively unlocked.
        case unlocked
        
        /// Requires the device to be actively unlocked, and disallows iCloud keychain sharing.
        case unlockedThisDeviceOnly
        
        /// Requires the device to have been unlocked at some point.
        case afterFirstUnlock

        /// Requires the device to have been unlocked at some point, and disallows iCloud keychain sharing.
        case afterFirstUnlockThisDeviceOnly

        /// Requires the device to have a passcode set, and disallows iCloud keychain sharing.
        @available(iOS 8.0, *)
        case whenPasswordSetThisDeviceOnly

        /// Allows the keychain item to always be accessible.
        @available(iOS, introduced: 4.0, deprecated: 12.0, message: "Use an accessibility level that provides some user protection, such as kSecAttrAccessibleAfterFirstUnlock")
        case always

        /// Allows the keychain item to always be accessible, and disallows iCloud keychain sharing.
        @available(iOS, introduced: 4.0, deprecated: 12.0, message: "Use an accessibility level that provides some user protection, such as kSecAttrAccessibleAfterFirstUnlock")
        case alwaysThisDeviceOnly
        
        var isSynchronizable: Bool {
            switch self {
            case .unlocked, .afterFirstUnlock, .always:
                return true
            case .unlockedThisDeviceOnly, .afterFirstUnlockThisDeviceOnly, .whenPasswordSetThisDeviceOnly, .alwaysThisDeviceOnly:
                return false
            }
        }
    }
    
    /// Defines a search for keychain items.
    public struct Search {
        /// The account ID or key to use for searching.
        ///
        /// When this value is `nil`, all items that match the remaining criteria will be returned.
        public let account: String?
        
        /// The service name the various accounts are grouped within.
        ///
        /// When this value is `nil`, all items that match the remaining criteria will be returned.
        public let service: String?

        /// The server the various accounts are grouped within.
        ///
        /// When this value is `nil`, all items that match the remaining criteria will be returned.
        public let server: String?

        /// The access group the items returned should be stored in.
        ///
        /// When this value is `nil`, all items that match the remaining criteria will be returned.
        public let accessGroup: String?
        
        /// Designated initializer.
        /// - Parameters:
        ///   - account: The account to search for, or `nil` to return all accounts.
        ///   - service: The service to search for, or `nil` to return all services.
        ///   - accessGroup: The access group to search within, or `nil` to return all access groups.
        public init(account: String? = nil, service: String? = nil, server: String? = nil, accessGroup: String? = nil) {
            self.account = account
            self.service = service
            self.server = server
            self.accessGroup = accessGroup
        }
        
        /// Gets the first item matching this search criteria.
        ///
        /// This will attempt to read the secret data contained within the keychain item represented by this search query. If the item cannot be read, either because it does not exist, or if the device is in an incompatible state, this will throw an exception.
        /// - Parameters:
        ///   - prompt: Optional message to show to the user when prompting the user for biometric/Face ID.
        ///   - authenticationContext: Optional `LAContext` to use when updating the item, on platforms that support it.
        /// - Returns: The keychain item defined by this search query.
        public func get(prompt: String? = nil, authenticationContext: KeychainAuthenticationContext? = nil) throws -> Item {
            try performGet(prompt: prompt,
                           authenticationContext: authenticationContext)
        }
        
        /// Returns the list of keychain items matching this search criteria.
        ///
        /// This will return an array of ``Keychain/Search/Result`` objects that define the results of the search.  Each of those result objects may be inspected for their public information, as well as can be used to retrieve the secret value data associated with individual results.
        /// - Returns: Array of ``Keychain/Search/Result`` objects matching this search.
        public func list() throws -> [Result] {
            try performList()
        }
        
        /// Deletes all items mathcing this search.
        public func delete() throws {
            try performDelete()
        }

        /// An individual result within a keychain search.
        public struct Result {
            /// The account for this item.
            public let account: String
            
            /// The service name for this keychain item.
            public let service: String?
            
            /// The server for this keychain item.
            public let server: String?
            
            /// The access group for this keychain item.
            public let accessGroup: String?
            
            /// The label that summarizes this keychain item.
            public let label: String?
            
            /// The description for this keychain item.
            public let description: String?
            
            /// The accessibility level for this keychain item.
            public var accessibility: Accessibility?
            
            /// Indicates whether or not this keychain item may be synchronized to iCloud Keychain.
            public var synchronizable: Bool?

            /// The access control settings for this item.
            public var accessControl: SecAccessControl?
            
            /// The generic, publicly-visible, data associated with this keychain item.
            public let generic: Data?
            
            /// The date this keychain item was created.
            public let creationDate: Date
            
            /// The date this keychain item was modified.
            public let modificationDate: Date

            init(_ result: [String: Any]) throws {
                guard let account = result[kSecAttrAccount as String] as? String else {
                    throw KeychainError.missingAccount
                }
                
                guard let creationDate = result[kSecAttrCreationDate as String] as? Date,
                      let modificationDate = result[kSecAttrModificationDate as String] as? Date
                else {
                    throw KeychainError.missingAttribute
                }

                self.account = account
                self.creationDate = creationDate
                self.modificationDate = modificationDate
                service = result[kSecAttrService as String] as? String
                server = result[kSecAttrServer as String] as? String
                accessGroup = result[kSecAttrAccessGroup as String] as? String
                label = result[kSecAttrLabel as String] as? String
                description = result[kSecAttrDescription as String] as? String
                generic = result[kSecAttrGeneric as String] as? Data
                synchronizable = result[kSecAttrSynchronizable as String] as? Bool
                
                guard let accessibilityString = result[kSecAttrAccessible as String] as? String,
                      let accessibility = Keychain.Accessibility(rawValue: accessibilityString)
                else {
                    throw KeychainError.invalidAccessibilityOption
                }

                self.accessibility = accessibility
                
                if let value = result[kSecAttrAccessControl as String] {
                    // swiftlint:disable force_cast
                    accessControl = (value as! SecAccessControl)
                    // swiftlint:enable force_cast
                } else {
                    accessControl = nil
                }
            }
            
            /// Fetches the complete ``Keychain/Item`` for this individual search result.
            /// - Parameters:
            ///   - prompt: Optional message to show to the user when prompting the user for biometric/Face ID.
            ///   - authenticationContext: Optional `LAContext` to use when updating the item, on platforms that support it.
            /// - Returns: ``Keychain/Item`` represented by this search result.
            public func get(prompt: String? = nil, authenticationContext: KeychainAuthenticationContext? = nil) throws -> Item {
                try performGet(prompt: prompt,
                               authenticationContext: authenticationContext)
            }
            
            /// Updates the keychain item with the values supplied in the included item.
            /// - Parameters:
            ///   - item: Item whose values should replace the receiver's keychain item.
            ///   - authenticationContext: Optional `LAContext` to use when updating the item, on platforms that support it.
            public func update(_ item: Keychain.Item, authenticationContext: KeychainAuthenticationContext? = nil) throws {
                try performUpdate(item, authenticationContext: authenticationContext)
            }

            /// Deletes an individual search result.
            public func delete() throws {
                try performDelete()
            }
        }
    }
}

#endif
