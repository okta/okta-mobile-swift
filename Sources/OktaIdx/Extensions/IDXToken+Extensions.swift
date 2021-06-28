/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient.Token: NSSecureCoding {
    private enum Keys: String {
        case accessToken
        case refreshToken
        case expiresIn
        case idToken
        case scope
        case tokenType
        case configuration
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
              tokenType == object.tokenType,
              configuration == object.configuration
        else { return false }
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(accessToken, forKey: Keys.accessToken.rawValue)
        coder.encode(refreshToken, forKey: Keys.refreshToken.rawValue)
        coder.encode(expiresIn, forKey: Keys.expiresIn.rawValue)
        coder.encode(idToken, forKey: Keys.idToken.rawValue)
        coder.encode(scope, forKey: Keys.scope.rawValue)
        coder.encode(tokenType, forKey: Keys.tokenType.rawValue)
        coder.encode(configuration, forKey: Keys.configuration.rawValue)
    }
    
    public convenience init?(coder: NSCoder) {
        guard let accessToken = coder.decodeObject(of: [NSString.self],
                                                   forKey: Keys.accessToken.rawValue) as? String,
              let scope = coder.decodeObject(of: [NSString.self],
                                             forKey: Keys.scope.rawValue) as? String,
              let tokenType = coder.decodeObject(of: [NSString.self],
                                                 forKey: Keys.tokenType.rawValue) as? String,
              let configuration = coder.decodeObject(of: [IDXClient.Configuration.self],
                                                     forKey: Keys.configuration.rawValue) as? IDXClient.Configuration else
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
                  tokenType: tokenType,
                  configuration: configuration)
    }
}
