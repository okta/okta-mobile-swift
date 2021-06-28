//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient.Configuration: NSSecureCoding {
    private enum Keys: String {
        case issuer
        case clientId
        case clientSecret
        case scopes
        case redirectUri
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? IDXClient.Configuration,
              issuer == object.issuer,
              clientId == object.clientId,
              clientSecret == object.clientSecret,
              scopes == object.scopes,
              redirectUri == object.redirectUri
        else {
            return false
        }
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(issuer, forKey: Keys.issuer.rawValue)
        coder.encode(clientId, forKey: Keys.clientId.rawValue)
        coder.encode(clientSecret, forKey: Keys.clientSecret.rawValue)
        coder.encode(scopes, forKey: Keys.scopes.rawValue)
        coder.encode(redirectUri, forKey: Keys.redirectUri.rawValue)
    }

    public convenience init?(coder: NSCoder) {
        guard let issuer = coder.decodeObject(of: [NSString.self],
                                              forKey: Keys.issuer.rawValue) as? String,
              let clientId = coder.decodeObject(of: [NSString.self],
                                                forKey: Keys.clientId.rawValue) as? String,
              let clientSecret = coder.decodeObject(of: [NSString.self],
                                                    forKey: Keys.clientSecret.rawValue) as? String?,
              let scopes = coder.decodeObject(of: [NSArray.self],
                                              forKey: Keys.scopes.rawValue) as? [String],
              let redirectUri = coder.decodeObject(of: [NSString.self],
                                                   forKey: Keys.redirectUri.rawValue) as? String
        else {
            return nil
        }

        self.init(issuer: issuer,
                  clientId: clientId,
                  clientSecret: clientSecret,
                  scopes: scopes,
                  redirectUri: redirectUri)
    }
}

