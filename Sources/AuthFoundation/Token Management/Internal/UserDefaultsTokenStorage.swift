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
import OktaClientMacros

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

@HasLock
final class UserDefaultsTokenStorage: TokenStorage {
    nonisolated(unsafe) private let userDefaults: UserDefaults
    
    @Synchronized
    weak var delegate: (any TokenStorageDelegate)?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load all tokens
        if let data = userDefaults.data(forKey: UserDefaultsKeys.allTokensKey),
           let result = try? JSONDecoder().decode([String: Token].self, from: data)
        {
            self.allTokens = result
        } else {
            self.allTokens = [:]
        }
        
        // Load metadata
        if let data = userDefaults.data(forKey: UserDefaultsKeys.metadataKey),
           let result = try? JSONDecoder().decode([String: Token.Metadata].self, from: data)
        {
            self.metadata = result
        } else {
            self.metadata = [:]
        }
    }
    
    // Default token ID handling
    nonisolated(unsafe) var _defaultTokenID: String?
    private func _getDefaultTokenID() -> String? {
        guard _defaultTokenID == nil else {
            return _defaultTokenID
        }
        
        if let defaultAccessKey = userDefaults.string(forKey: UserDefaultsKeys.defaultTokenKey) {
            _defaultTokenID = defaultAccessKey
        }

        return _defaultTokenID
    }
    
    func _setDefaultTokenID(_ id: String?) {
        guard _defaultTokenID != id else { return }
        _defaultTokenID = id
        
        if let id = id {
            userDefaults.set(id, forKey: UserDefaultsKeys.defaultTokenKey)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.defaultTokenKey)
        }
        userDefaults.synchronize()
    }

    var defaultTokenID: String? {
        get {
            withLock {
                _getDefaultTokenID()
            }
        }
    }

    func setDefaultTokenID(_ id: String?) throws {
        withLock {
            _setDefaultTokenID(id)
        }
    }

    nonisolated(unsafe) private var allTokens: [String: Token]
    nonisolated(unsafe) private var metadata: [String: Token.Metadata]
    
    var allIDs: [String] {
        withLock {
            Array(allTokens.keys)
        }
    }
    
    func get(token id: String, prompt: String? = nil, authenticationContext: (any TokenAuthenticationContext)? = nil) throws -> Token {
        try withLock {
            guard let token = allTokens[id] else {
                throw TokenError.tokenNotFound(id: id)
            }
            
            return token
        }
    }
    
    func add(token: Token, security: [Credential.Security]) throws {
        try withLock {
            let metadata = Token.Metadata(token: token)
            guard token.id == metadata.id else {
                throw CredentialError.metadataConsistency
            }
            
            let id = token.id
            
            guard !allTokens.keys.contains(id) else {
                throw TokenError.duplicateTokenAdded
            }
            
            allTokens[id] = token
            self.metadata[id] = metadata
            
            try save()
            
            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, added: id, token: token)
                }
            }
        }
    }
    
    func update(token: Token, security: [Credential.Security]?) throws {
        try withLock {
            guard allTokens[token.id] != nil else {
                throw TokenError.cannotReplaceToken
            }
            allTokens[token.id] = token
            metadata[token.id] = Token.Metadata(token: token)
            
            try save()
            
            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, replaced: token.id, with: token)
                }
            }
        }
    }
    
    func remove(id: String) throws {
        try withLock {
            guard allTokens[id] != nil else {
                return
            }
            
            allTokens.removeValue(forKey: id)
            
            try save()
            
            if let delegate = _delegate {
                DispatchQueue.global().async {
                    delegate.token(storage: self, removed: id)
                }
            }
            
            if _getDefaultTokenID() == id {
                _setDefaultTokenID(nil)
            }
        }
    }
    
    func metadata(for id: String) throws -> Token.Metadata {
        withLock {
            metadata[id] ?? Token.Metadata(id: id, configuration: nil)
        }
    }

    private func save() throws {
        defer { userDefaults.synchronize() }
        
        userDefaults.set(try JSONEncoder().encode(allTokens),
                         forKey: UserDefaultsKeys.allTokensKey)
        userDefaults.set(try JSONEncoder().encode(metadata),
                         forKey: UserDefaultsKeys.metadataKey)
    }
}
