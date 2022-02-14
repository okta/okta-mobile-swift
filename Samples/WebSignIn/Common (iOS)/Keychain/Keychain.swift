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

public final class Keychain {
    
    enum Error: Swift.Error {
        case codingError
        case failed(String)
        case notFound
    }

    /**
     Stores an item securely in the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     - string: String to store inside of the keychain
     */
    public static func set(key: String, string: String, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        guard let objectData = string.data(using: .utf8) else {
            throw Keychain.Error.codingError
        }
        
        try set(key: key, data: objectData, accessGroup: accessGroup, accessibility: accessibility)
    }
    
    /**
     Stores an item securely in the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     - data: Data to store inside of the keychain
     */
    public static func set(key: String, data: Data, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        var query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String: Any]
        
        if let accessGroup = accessGroup {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue!
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let cfDictionary = query as CFDictionary
        // Delete existing (if applicable)
        SecItemDelete(cfDictionary)
        
        let sanityCheck = SecItemAdd(cfDictionary, nil)
        if sanityCheck != noErr {
            throw Keychain.Error.failed(sanityCheck.description)
        }        
    }
    
    /**
     Retrieve the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    public static func get(key: String, accessGroup: String? = nil) throws -> String {
        let data: Data = try get(key: key, accessGroup: accessGroup)
        guard let string = String(data: data, encoding: .utf8) else {
            throw Keychain.Error.codingError
        }
        return string
    }
    
    /**
     Retrieve the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    public static func get(key: String, accessGroup: String? = nil) throws -> Data {
        var query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        if let accessGroup = accessGroup {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue!
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let cfQuery = query as CFDictionary
        var ref: AnyObject?
        
        let sanityCheck = SecItemCopyMatching(cfQuery, &ref)
        guard sanityCheck == noErr else {
            if sanityCheck == errSecItemNotFound {
                throw Keychain.Error.notFound
            } else {
                throw Keychain.Error.failed(sanityCheck.description)
            }
        }
        
        guard let data = ref as? Data else {
            throw Keychain.Error.failed("No data for \(key)")
        }
        
        return data
    }
    
    /**
     Remove the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    public static func remove(key: String, accessGroup: String? = nil) throws {
        let data: Data = try get(key: key, accessGroup: accessGroup)
        var query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        if let accessGroup = accessGroup {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue!
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete existing (if applicable)
        let cfQuery = query as CFDictionary
        let sanityCheck: OSStatus = SecItemDelete(cfQuery)
        
        guard sanityCheck == noErr else {
            throw Keychain.Error.failed(sanityCheck.description)
        }
    }
    
    /// Removes all entities from the Keychain.
    public static func clearAll() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secItemClass in secItemClasses {
            let dictionary = [ kSecClass as String: secItemClass ] as CFDictionary
            SecItemDelete(dictionary)
        }
    }
}
