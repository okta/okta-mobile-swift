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

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

extension Array where Element == Credential.Security {
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    #if canImport(LocalAuthentication) && !os(tvOS)
    var context: LAContext? {
        for case let Credential.Security.context(value) in self {
            return value
        }
        return nil
    }
    #endif

    var accessibility: Keychain.Accessibility? {
        for case let Credential.Security.accessibility(value) in self {
            return value
        }
        return nil
    }

    var accessGroup: String? {
        for case let Credential.Security.accessGroup(value) in self {
            return value
        }
        return nil
    }

    var accessControlFlags: SecAccessControlCreateFlags? {
        for case let Credential.Security.accessControl(value) in self {
            return value
        }
        return nil
    }
    
    var accessControlRef: SecAccessControl? {
        for case let Credential.Security.accessControlRef(value) in self {
            return value
        }
        return nil
    }
    
    func createAccessControl(accessibility: Keychain.Accessibility) throws -> SecAccessControl? {
        if let accessControlRef = accessControlRef {
            return accessControlRef
        }
        
        guard let accessControlFlags = accessControlFlags else {
            return nil
        }

        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                            accessibility.rawValue as CFTypeRef,
                                                            accessControlFlags,
                                                            &error)
        if let error = error?.takeRetainedValue() {
            let desc = CFErrorCopyDescription(error)
            let code = CFErrorGetCode(error)
            
            throw KeychainError.accessControlInvalid(code: OSStatus(code),
                                                     description: desc as String?)
        }
        
        return accessControl
    }
    #endif
}
