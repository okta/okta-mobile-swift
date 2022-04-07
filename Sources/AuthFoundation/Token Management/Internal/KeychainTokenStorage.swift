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

class KeychainTokenStorage: TokenStorage {
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
        let result = try? Keychain
            .Search(service: KeychainTokenStorage.serviceName)
            .list()
            .map { $0.account }
        
        return result ?? []
    }
    
    func add(token: Token) throws {
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
        
        // TODO: Update keychain handling to abstract ID generation, and support custom access groups, accessibility options, and to provide the ability to separate secret data and generic data.
        let item = Keychain.Item(account: id,
                                 service: KeychainTokenStorage.serviceName,
                                 accessibility: .unlocked,
                                 accessGroup: nil,
                                 synchronizable: nil,
                                 label: nil,
                                 description: nil,
                                 generic: nil,
                                 value: data)
        try item.save()

        delegate?.token(storage: self, added: id, token: token)
        
        if changedDefault {
            try setDefaultTokenID(id)
        }
    }
    
    func replace(token id: String, with token: Token) throws {
        let oldResult = try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.serviceName)
            .get()
        
        let oldToken = try self.token(with: oldResult)
        try oldResult.delete()
        
        token.id = id
        
        let data = try encoder.encode(token)
        try Keychain
            .Item(account: id,
                  service: KeychainTokenStorage.serviceName,
                  accessibility: .unlocked,
                  value: data)
            .save()
        
        delegate?.token(storage: self, replaced: id, from: oldToken, to: token)
    }
    
    func remove(id: String) throws {
        try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.serviceName)
            .get()
            .delete()

        try Keychain
            .Search(account: id,
                    service: KeychainTokenStorage.serviceName,
                    accessGroup: nil)
            .get()
            .delete()
        
        delegate?.token(storage: self, removed: id)

        if defaultTokenID == id {
            try setDefaultTokenID(nil)
        }
    }
    
    func get(token id: String) throws -> Token {
        try token(with: try Keychain
                    .Search(account: id,
                            service: KeychainTokenStorage.serviceName)
                    .get())
    }
    
    func setMetadata(_ metadata: Token.Metadata) throws {
        guard allIDs.contains(metadata.id) else {
            throw TokenError.tokenNotFound(id: metadata.id)
        }
        
        try Keychain
            .Item(account: metadata.id,
                  service: KeychainTokenStorage.metadataName,
                  accessibility: .afterFirstUnlock,
                  value: try encoder.encode(metadata))
            .save()
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
                .get()
                .delete()
        }
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
}

#endif
