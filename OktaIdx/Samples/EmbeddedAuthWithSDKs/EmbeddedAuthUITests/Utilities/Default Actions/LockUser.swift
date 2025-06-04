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

extension Scenario {
    func lockUser(username: String,
                  times: Int = 5)
    {
        guard let url = URL(string: configuration.issuerUrl)?.appendingPathComponent("v1/token") else {
            return
        }
        
        let group = DispatchGroup()
        for _ in 1...times {
            let params = [
                "client_id": configuration.clientId,
                "scope": configuration.scopes,
                "grant_type": "password",
                "username": username,
                "password": UUID().uuidString
            ]
            let bodyString = params.reduce(into: [String]()) { partialResult, item in
                let key = item.key as NSString,
                    value = item.value as NSString
                
                guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                else { return }
                                                           
                partialResult.append("\(encodedKey)=\(encodedValue)")
            }.joined(separator: "&")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            group.enter()
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                group.leave()
            }).resume()
            group.wait()
        }
    }
}
