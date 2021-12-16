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
import OktaIdx

public struct User: Codable {
    let token: Token
    let info: Info
    
    init(token: Token, info: Info) {
        self.token = token
        self.info = info
    }
    
    public struct Info: Codable {
        let familyName: String
        let givenName: String
        let name: String
        let preferredUsername: String
        let sub: String
        let updatedAt: Date
        let locale: String
        let zoneinfo: String

        static let jsonDecoder: JSONDecoder = {
            let result = JSONDecoder()
            result.dateDecodingStrategy = .secondsSince1970
            result.keyDecodingStrategy = .convertFromSnakeCase
            return result
        }()
    }
}

public class UserManager {
    static let shared = UserManager()
    var configuration: IDXClient.Configuration? = ClientConfiguration.active?.idxConfiguration
    
    private struct UserDefaultsKeys {
        static let storedTokenKey = "com.okta.example.storedToken"
    }
    
    private var _current: User? {
        didSet {
            NotificationCenter.default.post(name: .userChanged, object: _current)
        }
    }

    var current: User? {
        get {
            if _current == nil,
               let data = UserDefaults.standard.object(forKey: UserDefaultsKeys.storedTokenKey) as? Data
            {
                _current = try? JSONDecoder().decode(User.self, from: data)
            }
            return _current
        }
        set {
            let defaults = UserDefaults.standard
            _current = newValue
            if let currentUser = _current {
                let data = try? JSONEncoder().encode(currentUser)
                defaults.set(data, forKey: UserDefaultsKeys.storedTokenKey)
            } else {
                defaults.removeObject(forKey: UserDefaultsKeys.storedTokenKey)
            }
            defaults.synchronize()
        }
    }
}
