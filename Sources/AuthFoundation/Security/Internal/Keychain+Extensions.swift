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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

import Foundation

protocol KeychainQuery {
    var query: [String: Any] { get }
}

protocol KeychainGettable: KeychainQuery {
    var getQuery: [String: Any] { get }
}

protocol KeychainListable: KeychainQuery {
    var listQuery: [String: Any] { get }
}

protocol KeychainUpdatable: KeychainQuery {
    var updateQuery: [String: Any] { get }
}

protocol KeychainDeletable: KeychainQuery {
    var deleteQuery: [String: Any] { get }
}

extension KeychainGettable {
    var getQuery: [String: Any] {
        var result = self.query
        result[kSecMatchLimit as String] = kSecMatchLimitOne
        result[kSecReturnData as String] = kCFBooleanTrue
        return result
    }

    func performGet(prompt: String?, authenticationContext: KeychainAuthenticationContext?) throws -> Keychain.Item {
        var cfQuery = self.getQuery
        if let prompt = prompt {
            cfQuery[kSecUseOperationPrompt as String] = prompt
        }
        
        if let authenticationContext = authenticationContext {
            cfQuery[kSecUseAuthenticationContext as String] = authenticationContext
        }

        var ref: AnyObject?
        
        let status = Keychain.implementation.copyItemMatching(cfQuery as CFDictionary, &ref)
        guard status == noErr else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            } else {
                throw KeychainError.cannotGet(code: status)
            }
        }
        
        guard let result = ref as? [String: Any] else {
            throw KeychainError.invalidFormat
        }
        
        return try Keychain.Item(result)
    }
}

extension KeychainListable {
    var listQuery: [String: Any] {
        var result = self.query
        result[kSecMatchLimit as String] = kSecMatchLimitAll
        result.removeValue(forKey: kSecValueData as String)
        return result
    }

    func performList() throws -> [Keychain.Search.Result] {
        let cfQuery = self.listQuery as CFDictionary
        var ref: CFTypeRef?
        let status = Keychain.implementation.copyItemMatching(cfQuery, &ref)
        
        guard status != errSecItemNotFound else {
            return []
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.cannotList(code: status)
        }
        
        guard let items = ref as? [[String: Any]] else {
            throw KeychainError.invalidFormat
        }

        return try items.map { try Keychain.Search.Result($0) }
    }
}

extension KeychainUpdatable {
    var updateQuery: [String: Any] {
        query.filter { (key: String, _: Any) in
            let keyAttr = key as CFString
            switch keyAttr {
            case kSecClass: fallthrough
            case kSecAttrService: fallthrough
            case kSecAttrServer: fallthrough
            case kSecAttrAccessGroup: fallthrough
            case kSecAttrAccount:
                return true
            default:
                return false
            }
        }
    }

    func performUpdate(_ item: Keychain.Item, authenticationContext: KeychainAuthenticationContext?) throws {
        let updateSearchQuery = self.updateQuery

        var saveQuery = item.query
        saveQuery.removeValue(forKey: kSecClass as String)
        
        if let authenticationContext = authenticationContext {
            saveQuery[kSecUseAuthenticationContext as String] = authenticationContext
        }

        let status = Keychain.implementation.updateItem(updateSearchQuery as CFDictionary, saveQuery as CFDictionary)
        if status == errSecItemNotFound {
            throw KeychainError.notFound
        } else if status != noErr {
            throw KeychainError.cannotUpdate(code: status)
        }
    }
}

extension KeychainDeletable {
    var deleteQuery: [String: Any] {
        var cfQuery = self.query
        cfQuery.removeValue(forKey: kSecMatchLimit as String)
        cfQuery.removeValue(forKey: kSecReturnAttributes as String)
        cfQuery.removeValue(forKey: kSecReturnRef as String)
        
        return cfQuery
    }

    func performDelete() throws {
        let status = Keychain.implementation.deleteItem(deleteQuery as CFDictionary)
        if status == errSecItemNotFound {
            throw KeychainError.notFound
        } else if status != noErr {
            throw KeychainError.cannotDelete(code: status)
        }
    }
}

extension Keychain.Item: KeychainUpdatable, KeychainDeletable {
    var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecAttrAccount as String] = account
        result[kSecValueData as String] = value
        
        if let accessibility = accessibility {
            result[kSecAttrAccessible as String] = accessibility.rawValue
        }
        
        if #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            result[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        
        if let service = service {
            result[kSecAttrService as String] = service
        }
        
        if let server = server {
            result[kSecAttrServer as String] = server
        }
        
        if let accessGroup = accessGroup {
            result[kSecAttrAccessGroup as String] = accessGroup
        }
        
        if let synchronizable = synchronizable {
            result[kSecAttrSynchronizable as String] = synchronizable ? kCFBooleanTrue : kCFBooleanFalse
        }

        if let label = label {
            result[kSecAttrLabel as String] = label
        }
        
        if let description = description {
            result[kSecAttrDescription as String] = description
        }
        
        if let generic = generic {
            result[kSecAttrGeneric as String] = generic
        }
        
        return result
    }
}

extension Keychain.Search: KeychainGettable, KeychainListable, KeychainDeletable {
    var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecReturnRef as String] = kCFBooleanTrue
        result[kSecReturnAttributes as String] = kCFBooleanTrue
        result[kSecAttrAccount as String] = account
        
        if let service = service {
            result[kSecAttrService as String] = service
        }
        
        if let server = server {
            result[kSecAttrServer as String] = server
        }

        if let accessGroup = accessGroup {
            result[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return result
    }
}

extension Keychain.Search.Result: KeychainGettable, KeychainUpdatable, KeychainDeletable {
    var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecReturnRef as String] = kCFBooleanTrue
        result[kSecReturnAttributes as String] = kCFBooleanTrue
        result[kSecAttrAccount as String] = account

        if let service = service {
            result[kSecAttrService as String] = service
        }
        
        if let server = server {
            result[kSecAttrServer as String] = server
        }

        if let accessGroup = accessGroup {
            result[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return result
    }
}

extension Keychain.Accessibility: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        let cfValue = rawValue as CFString
        switch cfValue {
        case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly:
            self = .whenPasswordSetThisDeviceOnly
        case kSecAttrAccessibleWhenUnlocked:
            self = .unlocked
        case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
            self = .unlockedThisDeviceOnly
        case kSecAttrAccessibleAfterFirstUnlock:
            self = .afterFirstUnlock
        case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
            self = .afterFirstUnlockThisDeviceOnly
        case kSecAttrAccessibleAlways:
            self = .always
        case kSecAttrAccessibleAlwaysThisDeviceOnly:
            self = .alwaysThisDeviceOnly
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .whenPasswordSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
        case .unlocked:
            return kSecAttrAccessibleWhenUnlocked as String
        case .unlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as String
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        case .always:
            return kSecAttrAccessibleAlways as String
        case .alwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly as String
        }
    }
}

#endif
