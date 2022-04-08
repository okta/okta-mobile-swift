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

/// Defines convenience mechanisms for interacting with the keychain, lincluding searching, creating, and deleting keychain items.
public struct Keychain {
    static var implementation: KeychainProtocol = KeychainImpl()
    
    /// Defines an individual keychain item. This may be created using the designated initializer for the purposes of saving a new keychain item, or may be created as the result of getting a preexisting item from the keychain.
    public struct Item: Equatable {
        /// The account (also known as the key, or account ID) for this keychain item.
        public let account: String
        
        /// The service name this account is associated with.
        public let service: String?
        
        /// The accessibility level for this keychain item.
        public var accessibility: Accessibility
        
        /// Indicates whether or not this keychain item may be synchronized to iCloud Keychain.
        public var synchronizable: Bool?
        
        /// The access group this keychain item is stored within.
        public var accessGroup: String?
        
        /// The human-readable summary for this keychain item.
        public var label: String?
        
        /// The human-readable description for this keychain item.
        public var description: String?
        
        /// The generic, publicly-visible, data associated with this keychain item.
        public var generic: Data?
        
        /// The secret / private stored within this keychain item.
        public var value: Data
        
        /// Saves the item to the keychain.
        public func save() throws {
            let cfDictionary = query as CFDictionary

            Keychain.implementation.deleteItem(cfDictionary)
            
            let status = Keychain.implementation.addItem(cfDictionary, nil)
            if status != noErr {
                throw KeychainError.cannotSave(code: status)
            }
        }
        
        /// Deletes this keychain item.
        public func delete() throws {
            let cfDictionary = query as CFDictionary

            let status = Keychain.implementation.deleteItem(cfDictionary)
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            } else if status != noErr {
                throw KeychainError.cannotDelete(code: status)
            }
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
                    accessibility: Accessibility = .unlocked,
                    accessGroup: String? = nil,
                    synchronizable: Bool? = nil,
                    label: String? = nil,
                    description: String? = nil,
                    generic: Data? = nil,
                    value: Data)
        {
            self.account = account
            self.service = service
            self.accessibility = accessibility
            self.accessGroup = accessGroup
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
            accessGroup = result[kSecAttrAccessGroup as String] as? String
            label = result[kSecAttrLabel as String] as? String
            description = result[kSecAttrDescription as String] as? String
            generic = result[kSecAttrGeneric as String] as? Data
            synchronizable = result[kSecAttrSynchronizable as String] as? Bool
        }
    }
    
    /// Defines the accessibility level for keychain items.
    ///
    /// This is a convenience wrapper around the iOS `kSecAttrAccessible*` Core Foundation strings.
    public enum Accessibility {
        case unlocked
        case unlockedThisDeviceOnly
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly

        @available(iOS 8.0, *)
        case whenPasswordSetThisDeviceOnly

        @available(iOS, introduced: 4.0, deprecated: 12.0, message: "Use an accessibility level that provides some user protection, such as kSecAttrAccessibleAfterFirstUnlock")
        case always

        @available(iOS, introduced: 4.0, deprecated: 12.0, message: "Use an accessibility level that provides some user protection, such as kSecAttrAccessibleAfterFirstUnlock")
        case alwaysThisDeviceOnly
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

        /// The access group the items returned should be stored in.
        ///
        /// When this value is `nil`, all items that match the remaining criteria will be returned.
        public let accessGroup: String?
        
        /// Designated initializer.
        /// - Parameters:
        ///   - account: The account to search for, or `nil` to return all accounts.
        ///   - service: The service to search for, or `nil` to return all services.
        ///   - accessGroup: The access group to search within, or `nil` to return all access groups.
        public init(account: String? = nil, service: String? = nil, accessGroup: String? = nil) {
            self.account = account
            self.service = service
            self.accessGroup = accessGroup
        }
        
        /// Gets the first item matching this search criteria.
        ///
        /// This will attempt to read the secret data contained within the keychain item represented by this search query. If the item cannot be read, either because it does not exist, or if the device is in an incompatible state, this will throw an exception.
        /// - Returns: The keychain item defined by this search query.
        public func get() throws -> Item {
            let cfQuery = self.getQuery as CFDictionary
            var ref: AnyObject?
            
            let status = Keychain.implementation.copyItemMatching(cfQuery, &ref)
            guard status == noErr else {
                if status == errSecItemNotFound {
                    throw KeychainError.notFound
                } else {
                    throw KeychainError.cannotGet(code: status)
                }
            }
            
            guard let result = ref as? Dictionary<String, Any> else {
                throw KeychainError.invalidFormat
            }
            
            return try Item(result)
        }
        
        /// Returns the list of keychain items matching this search criteria.
        ///
        /// This will return an array of ``Keychain/Search/Result`` objects that define the results of the search.  Each of those result objects may be inspected for their public information, as well as can be used to retrieve the secret value data associated with individual results.
        /// - Returns: Array of ``Keychain/Search/Result`` objects matching this search.
        public func list() throws -> [Result] {
            let cfQuery = self.listQuery as CFDictionary
            var ref: CFTypeRef?
            let status = Keychain.implementation.copyItemMatching(cfQuery, &ref)
            
            guard status != errSecItemNotFound else {
                return []
            }
            
            guard status == errSecSuccess else {
                throw KeychainError.cannotList(code: status)
            }
            
            guard let items = ref as? Array<Dictionary<String, Any>> else {
                throw KeychainError.invalidFormat
            }

            return try items.map { try Result($0) }
        }
        
        /// An individual result within a keychain search.
        public struct Result {
            /// The account for this item.
            public let account: String
            
            /// The service name for this keychain item.
            public let service: String?
            
            /// The access group for this keychain item.
            public let accessGroup: String?
            
            /// The label that summarizes this keychain item.
            public let label: String?
            
            /// The description for this keychain item.
            public let description: String?
            
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
                accessGroup = result[kSecAttrAccessGroup as String] as? String
                label = result[kSecAttrLabel as String] as? String
                description = result[kSecAttrDescription as String] as? String
                generic = result[kSecAttrGeneric as String] as? Data
            }
            
            /// Fetches the complete ``Keychain/Item`` for this individual search result.
            /// - Returns: ``Keychain/Item`` represented by this search result.
            public func get() throws -> Item {
                let cfQuery = self.query as CFDictionary
                var ref: AnyObject?
                
                let status = Keychain.implementation.copyItemMatching(cfQuery, &ref)
                guard status == noErr else {
                    if status == errSecItemNotFound {
                        throw KeychainError.notFound
                    } else {
                        throw KeychainError.cannotGet(code: status)
                    }
                }
                
                guard let result = ref as? Dictionary<String, Any> else {
                    throw KeychainError.invalidFormat
                }
                
                return try Item(result)
            }
        }
    }
}

#endif
