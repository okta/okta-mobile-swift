//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

protocol CodeReceiver {
    var profile: A18NProfile { get }

    func reset(completion: @escaping () -> Void)
    func receiveCode(completion: @escaping (String?) -> Void)
    func waitForCode(timeout: TimeInterval, pollInterval: TimeInterval, completion: @escaping (String?) -> Void)
}

extension CodeReceiver {
    func waitForCode(timeout: TimeInterval = 45,
                     pollInterval: TimeInterval = 1,
                     completion: @escaping (String?) -> Void)
    {
        DispatchQueue.global().asyncAfter(deadline: .now() + pollInterval) {
            self.receiveCode { (code) in
                if code != nil {
                    completion(code)
                    return
                }

                let timeout = timeout - pollInterval
                if timeout < pollInterval {
                    completion(nil)
                } else {
                    self.waitForCode(timeout: timeout,
                                     pollInterval: pollInterval,
                                     completion: completion)
                }
            }
        }
    }
}

struct EmailCodeReceiver: CodeReceiver {
    let profile: A18NProfile

    func reset(completion: @escaping () -> Void) {
        profile.deleteAllMessages(of: A18NProfile.EmailMessage.self) { _ in
            completion()
        }
    }
    
    func receiveCode(completion: @escaping (String?) -> Void) {
        profile.message { (message: A18NProfile.EmailMessage?, error) in
            guard error == nil,
                  let message = message,
                  let code = try? message.content?.firstMatch(for: "enter this code: (\\d+)")?.firstMatch(for: "(\\d+)") ??
                    (try? message.content?.firstMatch(for: "Enter a code instead: (\\d+)")?.firstMatch(for: "(\\d+)"))
            else {
                completion(nil)
                return
            }
            
            completion(code)
        }
    }
}

struct EmailLinkReceiver: CodeReceiver {
    let profile: A18NProfile

    func reset(completion: @escaping () -> Void) {
        profile.deleteAllMessages(of: A18NProfile.EmailMessage.self) { _ in
            completion()
        }
    }
    
    func receiveCode(completion: @escaping (String?) -> Void) {
        profile.message { (message: A18NProfile.EmailMessage?, error) in
            guard error == nil,
                  let message = message,
                  let code = try? message.content?.firstMatch(for: "URL: (https://\\S+)")
            else {
                completion(nil)
                return
            }
            
            completion(code)
        }
    }
}

struct SMSReceiver: CodeReceiver {
    let profile: A18NProfile
    
    func reset(completion: @escaping () -> Void) {
        profile.deleteAllMessages(of: A18NProfile.SMSMessage.self) { _ in
            completion()
        }
    }
    
    func receiveCode(completion: @escaping (String?) -> Void) {
        profile.message { (message: A18NProfile.SMSMessage?, error) in
            guard error == nil,
                  let message = message,
                  let code = try? message.content.firstMatch(for: "code is (\\d+)")?.firstMatch(for: "(\\d+)")
            else {
                completion(nil)
                return
            }
            
            completion(code)
        }
    }
}

struct VoiceReceiver: CodeReceiver {
    let profile: A18NProfile
    
    func reset(completion: @escaping () -> Void) {
        profile.deleteAllMessages(of: A18NProfile.VoiceMessage.self) { _ in
            completion()
        }
    }
    
    func receiveCode(completion: @escaping (String?) -> Void) {
        profile.message { (message: A18NProfile.VoiceMessage?, error) in
            guard error == nil,
                  let message = message,
                  let code = try? message.content.firstMatch(for: "code is (\\d+)")
            else {
                completion(nil)
                return
            }
            
            completion(code)
        }
    }
}

fileprivate extension String {
    func firstMatch(for pattern: String) throws -> String? {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, options: [], range: range).map {
            String(self[Range($0.range, in: self)!])
        }.first
    }
}
