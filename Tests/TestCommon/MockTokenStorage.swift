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
import AuthFoundation

class MockTokenStorage: TokenStorage {
    var error: Error?
    
    var defaultTokenID: UUID? {
        didSet {
            if defaultTokenID != oldValue {
                delegate?.token(storage: self, defaultChanged: defaultTokenID)
            }
        }
    }
    
    func setDefaultTokenID(_ id: UUID?) throws {
        if let error = error {
            throw error
        }
        
        defaultTokenID = id
    }
    
    var allIDs: [UUID] { Array(allTokens.keys) }
    private var allTokens: [UUID:Token] = [:]
    private var metadata: [UUID:[String:String]] = [:]
    
    func add(token: Token, with id: UUID) throws {
        if let error = error {
            throw error
        }
        
        allTokens[id] = token
        delegate?.token(storage: self, added: id, token: token)
    }
    
    func assign(metadata: [String : String], for id: UUID) throws {
        if let error = error {
            throw error
        }
        
        self.metadata[id] = metadata
    }
    
    func metadata(for id: UUID) throws -> [String : String] {
        if let error = error {
            throw error
        }
        
        return metadata[id] ?? [:]
    }
    
    func replace(token id: UUID, with token: Token) throws {
        if let error = error {
            throw error
        }
        
        allTokens[id] = token
    }
    
    func remove(id: UUID) throws {
        if let error = error {
            throw error
        }
        
        allTokens.removeValue(forKey: id)
        metadata.removeValue(forKey: id)
    }
    
    func get(token id: UUID) throws -> Token {
        if let error = error {
            throw error
        }
        
        return allTokens[id]!
    }
    
    var delegate: TokenStorageDelegate?
}
