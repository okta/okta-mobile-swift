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
    static let allTokensKey = "com.okta.authfoundation.allTokens"
}

class DefaultTokenStorage: TokenStorage {
    private let userDefaults: UserDefaults
    
    weak var delegate: TokenStorageDelegate?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        try? load()
    }
    
    private var _defaultToken: Token?
    
    var defaultToken: Token? {
        get { _defaultToken }
        set {
            if let token = newValue {
                try? add(token: token)
            }
            
            if _defaultToken != newValue {
                _defaultToken = newValue
                try? save()
                
                delegate?.token(storage: self, defaultChanged: newValue)
            }
        }
    }
    
    private(set) var allTokens: [Token] = []
    
    func contains(token: Token) -> Bool {
        allTokens.contains(token)
    }
    
    func add(token: Token) throws {
        if let index = allTokens.firstIndex(of: token) {
            allTokens.remove(at: index)
            allTokens.insert(token, at: index)
            
            try save()
            delegate?.token(storage: self, updated: token)
        } else {
            var changedDefault = false
            if allTokens.count == 0 {
                _defaultToken = token
                changedDefault = true
            }
            
            allTokens.append(token)
            
            try save()
            delegate?.token(storage: self, added: token)

            if changedDefault {
                delegate?.token(storage: self, defaultChanged: token)
            }
        }
    }
    
    func remove(token: Token) throws {
        guard let index = allTokens.firstIndex(of: token) else { return }
        allTokens.remove(at: index)
        
        if _defaultToken == token {
            _defaultToken = nil
        }
        
        try save()
        delegate?.token(storage: self, removed: token)
    }
    
    private func load() throws {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.allTokensKey) {
            allTokens = try JSONDecoder().decode([Token].self, from: data)
        }
        
        if let defaultAccessKey = userDefaults.string(forKey: UserDefaultsKeys.defaultTokenKey) {
            _defaultToken = allTokens.first(where: { token in
                token.accessToken == defaultAccessKey
            })
        }
    }
    
    private func save() throws {
        userDefaults.set(try JSONEncoder().encode(allTokens),
                         forKey: UserDefaultsKeys.allTokensKey)

        if let currentUser = _defaultToken {
            userDefaults.set(currentUser.accessToken,
                             forKey: UserDefaultsKeys.defaultTokenKey)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKeys.defaultTokenKey)
        }

        userDefaults.synchronize()
    }
}
