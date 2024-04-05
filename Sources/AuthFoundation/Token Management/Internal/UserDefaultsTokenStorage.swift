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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(LocalAuthentication) && !os(tvOS)
import LocalAuthentication
#else
typealias LAContext = Void
#endif

private struct UserDefaultsKeys {
    static let defaultTokenKey = "com.okta.authfoundation.defaultToken"
    static let metadataKey = "com.okta.authfoundation.tokenMetadata"
    static let allTokensKey = "com.okta.authfoundation.allTokens"
}

final class UserDefaultsTokenStorage: TokenStorage {
    private let userDefaults: UserDefaults
    
    weak var delegate: TokenStorageDelegate?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    private(set) lazy var defaultTokenID: String? = {
        if let defaultAccessKey = userDefaults.string(forKey: UserDefaultsKeys.defaultTokenKey) {
            return defaultAccessKey
        }
        return nil
    }()
    
    private lazy var allTokens: [String: Token] = {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.allTokensKey),
           let result = try? JSONDecoder().decode([String: Token].self, from: data)
        {
            return result
        }
        return [:]
    }()
    
    private lazy var metadata: [String: Token.Metadata] = {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.metadataKey),
           let result = try? JSONDecoder().decode([String: Token.Metadata].self, from: data)
        {
            return result
        }
        return [:]
    }()
    
    func setDefaultTokenID(_ id: String?) throws {
        guard defaultTokenID != id else { return }
        defaultTokenID = id
        
        if let id = id {
            userDefaults.set(id, forKey: UserDefaultsKeys.defaultTokenKey)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.defaultTokenKey)
        }
        userDefaults.synchronize()
        delegate?.token(storage: self, defaultChanged: id)
    }
    
    var allIDs: [String] {
        Array(allTokens.keys)
    }
    
    func get(token id: String, prompt: String? = nil, authenticationContext: TokenAuthenticationContext? = nil) throws -> Token {
        guard let token = allTokens[id] else {
            throw TokenError.tokenNotFound(id: id)
        }
        
        return token
    }
    
    func add(token: Token, metadata: Token.Metadata?, security: [Credential.Security]) throws {
        let metadata = metadata ?? Token.Metadata(token: token, tags: [:])
        guard token.id == metadata.id else {
            throw CredentialError.metadataConsistency
        }
        
        let id = token.id
        
        guard !allTokens.keys.contains(id) else {
            throw TokenError.duplicateTokenAdded
        }

        var changedDefault = false
        if allTokens.isEmpty {
            changedDefault = true
        }
        
        allTokens[id] = token
        self.metadata[id] = metadata
        
        try save()
        delegate?.token(storage: self, added: id, token: token)
        
        if changedDefault {
            try setDefaultTokenID(id)
        }
    }
    
    func replace(token id: String, with token: Token, security: [Credential.Security]?) throws {
        guard allTokens[id] != nil else {
            throw TokenError.cannotReplaceToken
        }
        allTokens[id] = token
            
        try save()
        delegate?.token(storage: self, replaced: id, with: token)
    }
    
    func remove(id: String) throws {
        guard allTokens[id] != nil else {
            return
        }
        
        allTokens.removeValue(forKey: id)
        
        try save()
        delegate?.token(storage: self, removed: id)

        if defaultTokenID == id {
            try setDefaultTokenID(nil)
        }
    }
    
    func setMetadata(_ metadata: Token.Metadata) throws {
        guard allIDs.contains(metadata.id) else {
            throw TokenError.tokenNotFound(id: metadata.id)
        }
        
        self.metadata[metadata.id] = metadata
        
        try save()
    }
    
    func metadata(for id: String) throws -> Token.Metadata {
        metadata[id] ?? Token.Metadata(id: id)
    }

    private func save() throws {
        defer { userDefaults.synchronize() }
        
        userDefaults.set(try JSONEncoder().encode(allTokens),
                         forKey: UserDefaultsKeys.allTokensKey)
        userDefaults.set(try JSONEncoder().encode(metadata),
                         forKey: UserDefaultsKeys.metadataKey)
        userDefaults.synchronize()
    }
}
#endif
