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
    static let serviceName = "com.okta.authfoundation.keychainStorage"
    static let defaultTokenName = "com.okta.authfoundation.keychainStorage.default"

    weak var delegate: TokenStorageDelegate?
    
    init() {
        if let defaultResult = try? Keychain
            .Search(account: KeychainTokenStorage.defaultTokenName)
            .get()
        {
            _defaultTokenId = String(data: defaultResult.value, encoding: .utf8)
        }
    }
    
    private var _defaultTokenId: String?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var defaultToken: Token? {
        get {
            try? Keychain.Search().list()
            guard let tokenId = _defaultTokenId else { return nil }
            return try? cachedToken(with: tokenId)
        }
        set {
            if let token = newValue {
                try? add(token: token)
            }
            
            let tokenId = newValue?.id
            if _defaultTokenId != tokenId {
                _defaultTokenId = tokenId
                try? saveDefault()
                
                delegate?.token(storage: self, defaultChanged: newValue)
            }
        }
    }
    
    private var tokenCache: [String:Token?] = [:]
    var allTokens: [Token] {
        let result = try? Keychain
            .Search(service: KeychainTokenStorage.serviceName)
            .list()
            .compactMap { result -> Token? in
                try? cachedToken(with: result.account)
            }
        
        return result ?? []
    }
    
    func contains(token: Token) -> Bool {
        tokenCache.keys.contains(token.id)
    }
    
    func add(token: Token) throws {
        let tokenId = token.id
        guard try Keychain
                .Search(account: tokenId,
                      service: KeychainTokenStorage.serviceName)
                .list()
                .isEmpty
        else {
            throw TokenError.duplicateTokenAdded
        }

        let changedDefault = try Keychain
            .Search(service: KeychainTokenStorage.serviceName)
            .list()
            .count == 0
        
        tokenCache[tokenId] = token
        
        let data = try encoder.encode(token)
        
        // TODO: Update keychain handling to abstract ID generation, and support custom access groups, accessibility options, and to provide the ability to separate secret data and generic data.
        let item = Keychain.Item(account: token.id,
                                 service: KeychainTokenStorage.serviceName,
                                 accessibility: .unlocked,
                                 accessGroup: nil,
                                 synchronizable: nil,
                                 label: nil,
                                 description: nil,
                                 generic: nil,
                                 value: data)
        try item.save()
        
        if changedDefault {
            _defaultTokenId = tokenId
        }

        delegate?.token(storage: self, added: token)
        
        if changedDefault {
            try? saveDefault()
            delegate?.token(storage: self, defaultChanged: token)
        }
    }
    
    func replace(token: Token, with newToken: Token) throws {
        try Keychain
            .Search(account: token.id,
                    service: KeychainTokenStorage.serviceName)
            .get()
            .delete()
        
        let data = try encoder.encode(token)
        try Keychain
            .Item(account: token.id,
                  service: KeychainTokenStorage.serviceName,
                  accessibility: .unlocked,
                  value: data)
            .save()
        
        tokenCache.removeValue(forKey: token.id)
        tokenCache[newToken.id] = newToken
            
        var changedDefault = false
        if _defaultTokenId == token.id {
            changedDefault = true
            _defaultTokenId = newToken.id
            try? saveDefault()
        }
        
         delegate?.token(storage: self, replaced: token, with: newToken)
        
        if changedDefault {
            delegate?.token(storage: self, defaultChanged: token)
        }
    }
    
    func remove(token: Token) throws {
        try Keychain
            .Search(account: token.id,
                    service: KeychainTokenStorage.serviceName)
            .get()
            .delete()

        tokenCache.removeValue(forKey: token.id)
        
        if _defaultTokenId == token.id {
            _defaultTokenId = nil
            try? saveDefault()
            delegate?.token(storage: self, defaultChanged: nil)
        }
        
        try Keychain
            .Search(account: token.id,
                    service: KeychainTokenStorage.serviceName,
                    accessGroup: nil)
            .get()
            .delete()
        
        delegate?.token(storage: self, removed: token)
    }
    
    func cachedToken(with id: String) throws -> Token {
        if let token = tokenCache[id],
           let token = token
        {
            return token
        }
        
        let token = try token(with: id)
        tokenCache[id] = token
        return token
    }
    
    func token(with id: String) throws -> Token {
        try decoder.decode(Token.self,
                           from: try Keychain
                            .Search(account: id,
                                    service: KeychainTokenStorage.serviceName)
                            .get()
                            .value)
    }
    
    func token(with result: Keychain.Search.Result) throws -> Token {
        try decoder.decode(Token.self,
                           from: try result.get().value)
    }
    
    private func saveDefault() throws {
        if let tokenIdData = _defaultTokenId?.data(using: .utf8) {
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
}

#endif
