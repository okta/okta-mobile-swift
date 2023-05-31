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

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

final class KeychainTokenStorage: TokenStorage {
    static let serviceName = "com.okta.authfoundation.keychain.storage"
    static let metadataName = "com.okta.authfoundation.keychain.metadata"
    static let defaultTokenName = "com.okta.authfoundation.keychain.default"

    weak var delegate: TokenStorageDelegate?
    
    private(set) lazy var defaultTokenID: String? = {
        guard let defaultResult = try? Keychain
                .Search(account: KeychainTokenStorage.defaultTokenName)
                .get(),
              let id = String(data: defaultResult.value, encoding: .utf8)
        else {
            return nil
        }
        
        return id
    }()

    func setDefaultTokenID(_ id: String?) throws {
        guard defaultTokenID != id else { return }
        defaultTokenID = id
        try saveDefault()
        delegate?.token(storage: self, defaultChanged: id)
    }
    
    var allIDs: [String] {
        do {
            return try Keychain
                .Search(service: KeychainTokenStorage.metadataName)
                .list()
                .map(\.account)
        } catch {
            return []
        }
    }
    
    func add(token: Token, metadata: Token.Metadata?, security: [Credential.Security]) throws {
        let metadata = metadata ?? Token.Metadata(token: token, tags: [:])
        guard token.id == metadata.id else {
            throw CredentialError.metadataConsistency
        }
        
        let id = token.id
        
        guard try Keychain
                .Search(account: id,
                        service: KeychainTokenStorage.serviceName)
                .list()
                .isEmpty
        else {
            throw TokenError.duplicateTokenAdded
        }

        let changedDefault = try Keychain
            .Search(service: KeychainTokenStorage.serviceName)
            .list()
            .isEmpty
        
        let data = try encoder.encode(token)
        let accessibility = security.accessibility ?? .afterFirstUnlock
        let accessGroup = security.accessGroup
        let accessControl = try security.createAccessControl(accessibility: accessibility)
        
        let item = Keychain.Item(account: id,
                                 service: KeychainTokenStorage.serviceName,
                                 accessibility: accessibility,
                                 accessGroup: accessGroup,
                                 accessControl: accessControl,
                                 synchronizable: accessibility.isSynchronizable,
                                 label: nil,
                                 description: nil,
                                 generic: nil,
                                 value: data)
        
        let metadataItem = Keychain.Item(account: id,
                                         service: KeychainTokenStorage.metadataName,
                                         accessibility: .afterFirstUnlock,
                                         accessGroup: accessGroup,
                                         synchronizable: accessibility.isSynchronizable,
                                         value: try encoder.encode(metadata))

        var context: KeychainAuthenticationContext?
        #if canImport(LocalAuthentication) && !os(tvOS)
        context = security.context
        #endif

        try item.save(authenticationContext: context)
        try metadataItem.save(authenticationContext: context)

        delegate?.token(storage: self, added: id, token: token)
        
        if changedDefault {
            try setDefaultTokenID(id)
        }
    }
    
    func replace(token id: String, with token: Token, security: [Credential.Security]?) throws {
        guard let oldResult = try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.serviceName)
                .list()
                .first
        else {
            throw TokenError.cannotReplaceToken
        }
        
        token.id = id
        
        let data = try encoder.encode(token)
        let accessibility = security?.accessibility ?? oldResult.accessibility ?? .afterFirstUnlock
        let accessGroup = security?.accessGroup ?? oldResult.accessGroup
        let accessControl = try security?.createAccessControl(accessibility: accessibility) ?? oldResult.accessControl
        
        let newItem = Keychain.Item(account: id,
                                    service: KeychainTokenStorage.serviceName,
                                    accessibility: accessibility,
                                    accessGroup: accessGroup,
                                    accessControl: accessControl,
                                    synchronizable: accessibility.isSynchronizable,
                                    label: nil,
                                    description: nil,
                                    generic: nil,
                                    value: data)
        
        var context: KeychainAuthenticationContext?
        #if canImport(LocalAuthentication) && !os(tvOS)
        context = security?.context
        #endif

        try oldResult.update(newItem, authenticationContext: context)

        delegate?.token(storage: self, replaced: id, with: token)
    }
    
    func remove(id: String) throws {
        try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.metadataName)
            .delete()
        
        try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.serviceName)
            .delete()

        delegate?.token(storage: self, removed: id)

        if defaultTokenID == id {
            try setDefaultTokenID(nil)
        }
    }
    
    func get(token id: String, prompt: String? = nil, authenticationContext: TokenAuthenticationContext? = nil) throws -> Token {
        try token(with: try Keychain
                    .Search(account: id,
                            service: KeychainTokenStorage.serviceName)
                    .get(prompt: prompt,
                         authenticationContext: authenticationContext as? KeychainAuthenticationContext))
    }
    
    func setMetadata(_ metadata: Token.Metadata) throws {
        guard let result = try Keychain
            .Search(account: metadata.id,
                    service: KeychainTokenStorage.metadataName)
                .list()
                .first
        else {
            throw CredentialError.metadataConsistency
        }
        
        let item = Keychain.Item(account: result.account,
                                 service: result.service,
                                 value: try encoder.encode(metadata))

        try result.update(item)
    }

    func metadata(for id: String) throws -> Token.Metadata {
        try decoder.decode(Token.Metadata.self,
                           from: try Keychain
                            .Search(account: id,
                                    service: KeychainTokenStorage.metadataName)
                            .get()
                            .value)
    }
    
    private func token(with item: Keychain.Item) throws -> Token {
        try decoder.decode(Token.self,
                           from: item.value)
    }
    
    private func token(with result: Keychain.Search.Result) throws -> Token {
        try decoder.decode(Token.self,
                           from: try result.get().value)
    }
    
    private func saveDefault() throws {
        if let tokenIdData = defaultTokenID?.data(using: .utf8) {
            try Keychain
                .Item(account: KeychainTokenStorage.defaultTokenName,
                      accessibility: .afterFirstUnlock,
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
