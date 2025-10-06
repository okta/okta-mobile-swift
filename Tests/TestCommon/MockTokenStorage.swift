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

#if !COCOAPODS
import CommonSupport
#endif

@testable import AuthFoundation

class MockTokenStorage: @unchecked Sendable, TokenStorage {
    @LockedValue var error: (any Error)?
    @LockedValue var prompt: String?

    var defaultTokenID: String? {
        didSet {
            if defaultTokenID != oldValue {
                delegate?.token(storage: self, defaultChanged: defaultTokenID)
            }
        }
    }
    
    func setDefaultTokenID(_ id: String?) throws {
        if let error = error {
            throw error
        }
        
        defaultTokenID = id
    }
    
    var allIDs: [String] { Array(allTokens.keys) }
    private var allTokens: [String:(Token,[Credential.Security])] = [:]
    private var metadata: [String:Token.Metadata] = [:]
    
    func add(token: Token, metadata tokenMetadata: Token.Metadata?, security: [Credential.Security]) throws {
        let metadata: Token.Metadata
        if let tokenMetadata {
            metadata = tokenMetadata
        } else {
            metadata = try Token.Metadata(token: token, tags: [:])
        }

        if let error = error {
            throw error
        }
        
        let id = token.id
        allTokens[id] = (token, security)
        self.metadata[id] = metadata
        delegate?.token(storage: self, added: id, token: token)
    }
    
    func setMetadata(_ metadata: Token.Metadata) throws {
        guard allIDs.contains(metadata.id) else {
            throw TokenError.tokenNotFound(id: metadata.id)
        }
        
        if let error = error {
            throw error
        }
        
        self.metadata[metadata.id] = metadata
    }
    
    func metadata(for id: String) throws -> Token.Metadata {
        if let error = error {
            throw error
        }
        
        return metadata[id] ?? Token.Metadata(id: id)
    }
    
    func replace(token id: String, with token: Token, security: [Credential.Security]?) throws {
        if let error = error {
            throw error
        }
        
        guard let item = allTokens[id] else {
            throw TokenError.cannotReplaceToken
        }

        allTokens[id] = (token, item.1)
    }
    
    func remove(id: String) throws {
        if let error = error {
            throw error
        }
        
        allTokens.removeValue(forKey: id)
        metadata.removeValue(forKey: id)
    }
    
    func get(token id: String, prompt: String?, authenticationContext: (any TokenAuthenticationContext)? = nil) throws -> Token {
        if let error = error {
            throw error
        }
        
        self.prompt = prompt
        guard let item = allTokens[id] else {
            throw TokenError.tokenNotFound(id: id)
        }
        return item.0
    }

    var delegate: (any TokenStorageDelegate)?
}
