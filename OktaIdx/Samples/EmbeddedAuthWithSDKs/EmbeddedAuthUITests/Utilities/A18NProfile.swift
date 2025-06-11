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

protocol A18NMessage {
    static var messageType: A18NProfile.MessageType { get }
    var url: URL { get }
    func delete(completion: @escaping (Error?) -> Void)
}

struct A18NProfile: Codable {
    let profileId: String
    let phoneNumber: String
    let emailAddress: String
    let url: URL
    
    static func createProfile(using apiKey: String, completion: @escaping (A18NProfile?, Error?) -> Void) {
        guard let url = URL(string: "https://api.a18n.help/v1/profile") else {
            completion(nil, A18NError.invalidUrl)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "displayName": "okta-idx-swift"
        ], options: [])
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let profile = try? A18NProfile.jsonDecoder.decode(A18NProfile.self, from: data)
            else {
                completion(nil, error)
                return
            }
            completion(profile, nil)
        }.resume()
    }
    
    static func loadProfile(using apiKey: String, profileId: String, completion: @escaping (A18NProfile?, Error?) -> Void) {
        guard let url = URL(string: "https://api.a18n.help/v1/profile/\(profileId)") else {
            completion(nil, A18NError.invalidUrl)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let profile = try? A18NProfile.jsonDecoder.decode(A18NProfile.self, from: data)
            else {
                completion(nil, error)
                return
            }
            completion(profile, nil)
        }.resume()
    }
    
    func message<T: A18NMessage & Decodable>(_ messageId: String = "latest", completion: @escaping (T?, Error?) -> Void) {
        guard let url = URL(string: "https://api.a18n.help/v1/profile/\(profileId)/\(T.messageType.rawValue)/\(messageId)") else {
            completion(nil, A18NError.invalidUrl)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data,
                  let message = try? A18NProfile.jsonDecoder.decode(T.self, from: data)
            else {
                completion(nil, error)
                return
            }
            completion(message, nil)
        }.resume()
    }
    
    func delete(using apiKey: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "https://api.a18n.help/v1/profile/\(profileId)") else {
            completion(A18NError.invalidUrl)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(error)
        }.resume()
    }
    
    func deleteAllMessages(of type: A18NMessage.Type, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "https://api.a18n.help/v1/profile/\(profileId)/\(type.messageType.rawValue)") else {
            completion(A18NError.invalidUrl)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(error)
        }.resume()
    }
    
    struct EmailMessage: Codable, A18NMessage {
        static let messageType: MessageType = .email
        
        let createdAt: Date
        let fromAddress: String
        let messageId: String
        let profileId: String
        let subject: String
        let content: String?
        let toAddress: String
        let url: URL
    }
    
    struct SMSMessage: Codable, A18NMessage {
        static let messageType: MessageType = .sms
        
        let content: String
        let createdAt: Date
        let messageId: String
        let profileId: String
        let receiver: String
        let sender: String
        let url: URL
    }

    struct VoiceMessage: Codable, A18NMessage {
        static let messageType: MessageType = .voice
        
        let content: String
        let createdAt: Date
        let messageId: String
        let profileId: String
        let receiver: String
        let url: URL
    }
    
    enum MessageType: String {
        case email, sms, voice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileId = try container.decode(String.self, forKey: .profileId)
        emailAddress = try container.decode(String.self, forKey: .emailAddress)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        url = try container.decode(URL.self, forKey: .url)
    }

    fileprivate static let jsonDecoder: JSONDecoder = {
        let result = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        result.dateDecodingStrategy = .formatted(dateFormatter)
        
        return result
    }()
    
    private enum CodingKeys: String, CodingKey {
        case profileId, phoneNumber, emailAddress, url
    }
    
    enum A18NError: Error {
        case invalidUrl
    }
}

extension A18NMessage {
    func delete(completion: @escaping (Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(error)
        }.resume()
    }
}
