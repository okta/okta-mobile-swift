/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension IDXClient.Context: NSSecureCoding {
    private enum Keys: String {
        case state
        case interactionHandle
        case codeVerifier
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? IDXClient.Context else {
            return false
        }
        
        guard state == object.state,
              interactionHandle == object.interactionHandle,
              codeVerifier == object.codeVerifier else { return false }
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(state, forKey: Keys.state.rawValue)
        coder.encode(interactionHandle, forKey: Keys.interactionHandle.rawValue)
        coder.encode(codeVerifier, forKey: Keys.codeVerifier.rawValue)
    }
    
    public convenience init?(coder: NSCoder) {
        guard let state = coder.decodeObject(of: [NSString.self],
                                             forKey: Keys.state.rawValue) as? String,
              let interactionHandle = coder.decodeObject(of: [NSString.self],
                                                         forKey: Keys.interactionHandle.rawValue) as? String,
              let codeVerifier = coder.decodeObject(of: [NSString.self],
                                                    forKey: Keys.codeVerifier.rawValue) as? String else
        {
            return nil
        }
        
        self.init(state: state,
                  interactionHandle: interactionHandle,
                  codeVerifier: codeVerifier)
    }
}

extension IDXClient.Token: NSSecureCoding {
    private enum Keys: String {
        case accessToken
        case refreshToken
        case expiresIn
        case idToken
        case scope
        case tokenType
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? IDXClient.Token else {
            return false
        }
        
        guard accessToken == object.accessToken,
              refreshToken == object.refreshToken,
              expiresIn == object.expiresIn,
              idToken == object.idToken,
              scope == object.scope,
              tokenType == object.tokenType else { return false }
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(accessToken, forKey: Keys.accessToken.rawValue)
        coder.encode(refreshToken, forKey: Keys.refreshToken.rawValue)
        coder.encode(expiresIn, forKey: Keys.expiresIn.rawValue)
        coder.encode(idToken, forKey: Keys.idToken.rawValue)
        coder.encode(scope, forKey: Keys.scope.rawValue)
        coder.encode(tokenType, forKey: Keys.tokenType.rawValue)
    }
    
    public convenience init?(coder: NSCoder) {
        guard let accessToken = coder.decodeObject(of: [NSString.self],
                                                   forKey: Keys.accessToken.rawValue) as? String,
              let scope = coder.decodeObject(of: [NSString.self],
                                             forKey: Keys.scope.rawValue) as? String,
              let tokenType = coder.decodeObject(of: [NSString.self],
                                                 forKey: Keys.tokenType.rawValue) as? String else
        {
            return nil
        }
        
        let refreshToken = coder.decodeObject(of: [NSString.self],
                                              forKey: Keys.refreshToken.rawValue) as? String
        let idToken = coder.decodeObject(of: [NSString.self],
                                         forKey: Keys.idToken.rawValue) as? String
        let expiresIn = coder.decodeDouble(forKey: Keys.expiresIn.rawValue)
        self.init(accessToken: accessToken,
                  refreshToken: refreshToken,
                  expiresIn: expiresIn,
                  idToken: idToken,
                  scope: scope,
                  tokenType: tokenType)
    }
}
