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

extension IDXClient.Context: NSSecureCoding {
    private enum Keys: String {
        case configuration
        case state
        case interactionHandle
        case codeVerifier
        case version
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? IDXClient.Context,
              configuration == object.configuration,
              state == object.state,
              interactionHandle == object.interactionHandle,
              codeVerifier == object.codeVerifier,
              version == object.version
        else {
            return false
        }
        return true
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(configuration, forKey: Keys.configuration.rawValue)
        coder.encode(state, forKey: Keys.state.rawValue)
        coder.encode(interactionHandle, forKey: Keys.interactionHandle.rawValue)
        coder.encode(codeVerifier, forKey: Keys.codeVerifier.rawValue)
        coder.encode(version.rawValue, forKey: Keys.version.rawValue)
    }
    
    public convenience init?(coder: NSCoder) {
        guard let configuration = coder.decodeObject(of: [IDXClient.Configuration.self],
                                                     forKey: Keys.configuration.rawValue) as? IDXClient.Configuration,
              let state = coder.decodeObject(of: [NSString.self],
                                             forKey: Keys.state.rawValue) as? String,
              let interactionHandle = coder.decodeObject(of: [NSString.self],
                                                         forKey: Keys.interactionHandle.rawValue) as? String,
              let codeVerifier = coder.decodeObject(of: [NSString.self],
                                                    forKey: Keys.codeVerifier.rawValue) as? String,
              let versionNumber = coder.decodeObject(of: [NSString.self],
                                                     forKey: Keys.version.rawValue) as? String,
              let version = IDXClient.Version(rawValue: versionNumber) else
        {
            return nil
        }
        
        self.init(configuration: configuration,
                  state: state,
                  interactionHandle: interactionHandle,
                  codeVerifier: codeVerifier,
                  version: version)
    }
}
