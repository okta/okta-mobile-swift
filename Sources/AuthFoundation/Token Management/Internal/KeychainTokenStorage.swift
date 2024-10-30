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

#if canImport(Darwin)

import Foundation
import Keychain
import OktaConcurrency

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

@HasLock
final class KeychainTokenStorage: TokenStorage {
    static let serviceName = "com.okta.authfoundation.keychain.storage"
    static let metadataName = "com.okta.authfoundation.keychain.metadata"
    static let defaultTokenName = "com.okta.authfoundation.keychain.default"

    @Synchronized
    weak var delegate: (any TokenStorageDelegate)?
    
    // Default token ID handling
    nonisolated(unsafe) var _defaultTokenID: String?
    private func _getDefaultTokenID() throws -> String? {
        guard _defaultTokenID == nil else {
            return _defaultTokenID
        }
        
        if let defaultResult = try? Keychain
            .Search(account: KeychainTokenStorage.defaultTokenName)
            .get(),
           let id = String(data: defaultResult.value, encoding: .utf8)
        {
            _defaultTokenID = id
        }
        
        return _defaultTokenID
    }
    
    func _setDefaultTokenID(_ id: String?) throws {
        let currentValue = try? _getDefaultTokenID()
        guard currentValue != id else {
            return
        }
        
        _defaultTokenID = id
        
        try saveDefault()
        
        DispatchQueue.global().async {
            self.delegate?.token(storage: self, defaultChanged: id)
        }
    }

    var defaultTokenID: String? {
        get {
            withLock {
                try? _getDefaultTokenID()
            }
        }
    }

    func setDefaultTokenID(_ id: String?) throws {
        try withLock {
            try _setDefaultTokenID(id)
        }
    }
    
    var allIDs: [String] {
        withLock {
            do {
                let itemIDs = try Keychain
                    .Search(service: KeychainTokenStorage.serviceName)
                    .list()
                    .sorted(by: { $0.creationDate < $1.creationDate })
                    .map(\.account)
                let metadataIDs = try Keychain
                    .Search(service: KeychainTokenStorage.metadataName)
                    .list()
                    .map(\.account)
                return itemIDs.filter { metadataIDs.contains($0) }
            } catch {
                return []
            }
        }
    }
    
    func add(token: Token, security: [Credential.Security]) throws {
        try withLock {
            guard try Keychain
                .Search(account: token.id,
                        service: KeychainTokenStorage.serviceName)
                    .list()
                    .isEmpty
            else {
                throw TokenError.duplicateTokenAdded
            }
            
            var context: (any KeychainAuthenticationContext)?
            #if canImport(LocalAuthentication) && !os(tvOS)
            context = security.context
            #endif
            
            let (item, metadataItem) = try generateItems(for: token, security: security)

            try item.save(authenticationContext: context)
            try metadataItem.save(authenticationContext: context)
            
            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, added: token.id, token: token)
                }
            }
        }
    }
    
    func update(token: Token, security: [Credential.Security]?) throws {
        try withLock {
            guard let oldItem = try Keychain
                    .Search(account: token.id,
                        service: KeychainTokenStorage.serviceName)
                    .list()
                    .first,
                  let oldMetadataItem = try Keychain
                    .Search(account: token.id,
                        service: KeychainTokenStorage.metadataName)
                    .list()
                    .first
            else {
                throw TokenError.cannotReplaceToken
            }
            
            var context: (any KeychainAuthenticationContext)?
            #if canImport(LocalAuthentication) && !os(tvOS)
            context = security?.context
            #endif
            
            let (newItem, metadataItem) = try generateItems(for: token, security: security)
            try oldItem.update(newItem, authenticationContext: context)
            try oldMetadataItem.update(metadataItem, authenticationContext: context)

            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, replaced: token.id, with: token)
                }
            }
        }
    }
    
    func remove(id: String) throws {
        try withLock {
            try Keychain
                .Search(account: id,
                        service: KeychainTokenStorage.metadataName)
                .delete()
            
            try Keychain
                .Search(account: id,
                        service: KeychainTokenStorage.serviceName)
                .delete()
            
            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, removed: id)
                }
            }
            
            if try _getDefaultTokenID() == id {
                try _setDefaultTokenID(nil)
            }
        }
    }
    
    func get(token id: String, prompt: String? = nil, authenticationContext: (any TokenAuthenticationContext)? = nil) throws -> Token {
        try withLock {
            try token(with: try Keychain
                .Search(account: id,
                        service: KeychainTokenStorage.serviceName)
                    .get(prompt: prompt,
                         authenticationContext: authenticationContext as? (any KeychainAuthenticationContext)))
        }
    }
    
    func metadata(for id: String) throws -> Token.Metadata {
        try withLock {
            try decoder.decode(Token.Metadata.self,
                               from: try Keychain
                .Search(account: id,
                        service: KeychainTokenStorage.metadataName)
                    .get()
                    .value)
        }
    }
    
    private func token(with item: Keychain.Item) throws -> Token {
        try decoder.decode(Token.self,
                           from: item.value)
    }
    
    private func token(with result: Keychain.Search.Result) throws -> Token {
        try decoder.decode(Token.self,
                           from: try result.get().value)
    }
    
    private func generateItems(for token: Token,
                               security: [Credential.Security]?) throws -> (Keychain.Item, Keychain.Item)
    {
        let metadata = Token.Metadata(token: token)
        
        guard token.id == metadata.id else {
            throw CredentialError.metadataConsistency
        }

        let data = try encoder.encode(token)
        let accessAccessibility: Keychain.Accessibility?
        let accessGroup: String?
        let accessControl: SecAccessControl?
        let accessSynchronizable: Bool?
        let metadataAccessibility: Keychain.Accessibility?
        
        if let security = security {
            let accessibility = security.accessibility ?? .afterFirstUnlockThisDeviceOnly

            accessAccessibility = accessibility
            accessGroup = security.accessGroup
            accessControl = try security.createAccessControl(accessibility: accessibility)
            accessSynchronizable = accessibility.isSynchronizable

            if accessibility.isSynchronizable {
                metadataAccessibility = .afterFirstUnlock
            } else {
                metadataAccessibility = .afterFirstUnlockThisDeviceOnly
            }
        } else {
            accessAccessibility = nil
            accessGroup = nil
            accessControl = nil
            accessSynchronizable = nil
            metadataAccessibility = nil
        }
        
        let item = Keychain.Item(account: token.id,
                                 service: KeychainTokenStorage.serviceName,
                                 accessibility: accessAccessibility,
                                 accessGroup: accessGroup,
                                 accessControl: accessControl,
                                 synchronizable: accessSynchronizable,
                                 label: nil,
                                 description: nil,
                                 value: data)
        
        let metadataItem = Keychain.Item(account: token.id,
                                         service: KeychainTokenStorage.metadataName,
                                         accessibility: metadataAccessibility,
                                         accessGroup: accessGroup,
                                         synchronizable: accessSynchronizable,
                                         value: try encoder.encode(metadata))
    
        return (item, metadataItem)
    }
    
    private func saveDefault() throws {
        if let tokenIdData = _defaultTokenID?.data(using: .utf8) {
            let accessibility: Keychain.Accessibility
            if Credential.Security.isDefaultSynchronizable {
                accessibility = .afterFirstUnlock
            } else {
                accessibility = .afterFirstUnlockThisDeviceOnly
            }

            try Keychain
                .Item(account: KeychainTokenStorage.defaultTokenName,
                      accessibility: accessibility,
                      value: tokenIdData)
                .save()
        } else {
            try Keychain
                .Search(account: KeychainTokenStorage.defaultTokenName)
                .delete()
        }
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
}

#endif
