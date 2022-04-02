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

private struct UserDefaultsKeys {
    static let defaultTokenKey = "com.okta.authfoundation.defaultToken"
    static let metadataKey = "com.okta.authfoundation.tokenMetadata"
    static let allTokensKey = "com.okta.authfoundation.allTokens"
}

class UserDefaultsTokenStorage: TokenStorage {
    private let userDefaults: UserDefaults
    
    weak var delegate: TokenStorageDelegate?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    private(set) lazy var defaultTokenID: UUID? = {
        var result: UUID?
        if let defaultAccessKey = userDefaults.string(forKey: UserDefaultsKeys.defaultTokenKey) {
            result = UUID(uuidString: defaultAccessKey)
        }
        return result
    }()
    
    private lazy var allTokens: [UUID:Token] = {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.allTokensKey),
           let result = try? JSONDecoder().decode([UUID:Token].self, from: data)
        {
            return result
        }
        return [:]
    }()
    
    private lazy var metadata: [UUID:[String:String]] = {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.metadataKey),
           let result = try? JSONDecoder().decode([UUID:[String:String]].self, from: data)
        {
            return result
        }
        return [:]
    }()
    
    func setDefaultTokenID(_ id: UUID?) throws {
        guard defaultTokenID != id else { return }
        defaultTokenID = id
        
        if let id = id {
            userDefaults.set(id.uuidString, forKey: UserDefaultsKeys.defaultTokenKey)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.defaultTokenKey)
        }
        userDefaults.synchronize()
    }
    
    var allIDs: [UUID] {
        Array(allTokens.keys)
    }
    
    func get(token id: UUID) throws -> Token {
        guard let token = allTokens[id] else {
            throw TokenError.tokenNotFound(id: id)
        }
        
        return token
    }
    
    func add(token: Token, with id: UUID) throws {
        guard !allTokens.keys.contains(id) else {
            throw TokenError.duplicateTokenAdded
        } 

        var changedDefault = false
        if allTokens.count == 0 {
            changedDefault = true
        }
        
        allTokens[id] = token
        
        try save()
        delegate?.token(storage: self, added: id, token: token)
        
        if changedDefault {
            try setDefaultTokenID(id)
        }
    }
    
    func replace(token id: UUID, with token: Token) throws {
        guard let oldToken = allTokens[id] else {
            throw TokenError.cannotReplaceToken
        }
        allTokens[id] = token
            
        try save()
        delegate?.token(storage: self, replaced: id, from: oldToken, to: token)
    }
    
    func remove(id: UUID) throws {
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
    
    func assign(metadata: [String:String], for id: UUID) throws {
        self.metadata[id] = metadata
        
        try save()
    }
    
    func metadata(for id: UUID) throws -> [String:String] {
        metadata[id] ?? [:]
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
