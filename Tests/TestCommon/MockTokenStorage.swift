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
    var delegate: TokenStorageDelegate?
    
    var defaultToken: Token? {
        didSet {
            if defaultToken != oldValue {
                delegate?.token(storage: self, defaultChanged: defaultToken)
            }
        }
    }
    
    var allTokens: [Token] = []
    
    func contains(token: Token) -> Bool {
        allTokens.contains(token)
    }
    
    func add(token: Token) throws {
        allTokens.append(token)
        delegate?.token(storage: self, added: token)
    }
    
    func replace(token: Token, with newToken: Token) throws {
        guard let index = allTokens.firstIndex(of: token) else {
            throw TokenError.cannotReplaceToken
        }
        
        allTokens.remove(at: index)
        allTokens.insert(newToken, at: index)
        delegate?.token(storage: self, replaced: token, with: newToken)
    }
    
    func remove(token: Token) throws {
        guard let index = allTokens.firstIndex(of: token) else { return }
        allTokens.remove(at: index)
    }
}
