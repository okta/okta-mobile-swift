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

extension Keychain.Item {
    var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecAttrAccount as String] = account
        result[kSecValueData as String] = value
        result[kSecAttrAccessible as String] = accessibility.rawValue
        if #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            result[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        
        if let service = service {
            result[kSecAttrService as String] = service
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

extension Keychain.Search {
    fileprivate var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecReturnRef as String] = kCFBooleanTrue
        result[kSecReturnAttributes as String] = kCFBooleanTrue
        result[kSecAttrAccount as String] = account
        
        if let service = service {
            result[kSecAttrService as String] = service
        }

        if let accessGroup = accessGroup {
            result[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return result
    }
    
    var getQuery: [String: Any] {
        var result = self.query
        result[kSecMatchLimit as String] = kSecMatchLimitOne
        result[kSecReturnData as String] = kCFBooleanTrue
        return result
    }

    var listQuery: [String: Any] {
        var result = self.query
        result[kSecMatchLimit as String] = kSecMatchLimitAll
        return result
    }
}

extension Keychain.Search.Result {
    var query: [String: Any] {
        var result = [String: Any]()
        result[kSecClass as String] = kSecClassGenericPassword
        result[kSecMatchLimit as String] = kSecMatchLimitOne
        result[kSecReturnRef as String] = kCFBooleanTrue
        result[kSecReturnAttributes as String] = kCFBooleanTrue
        result[kSecReturnData as String] = kCFBooleanTrue
        result[kSecAttrAccount as String] = account

        if let service = service {
            result[kSecAttrService as String] = service
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
