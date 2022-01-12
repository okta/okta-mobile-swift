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

class DefaultUserDataSource: UserDataSource {
    private let queue = DispatchQueue(label: "com.okta.userDataSource.users",
                                      attributes: .concurrent)

    private var users: [Token: User] = [:]

    weak var delegate: UserDataSourceDelegate?

    var userCount: Int {
        queue.sync { users.count }
    }
    
    func user(for token: Token) -> User {
        queue.sync {
            if let user = users[token] {
                return user
            } else {
                let urlSession = self.urlSession(for: token)
                let client = OAuth2Client(baseURL: token.context.baseURL,
                                          session: urlSession)
                let user = User(token: token, oauth2: client)
                users[token] = user
                
                delegate?.user(dataSource: self, created: user)

                return user
            }
        }
    }
    
    func remove(user: User) {
        let _ = queue.sync(flags: .barrier) {
            users.removeValue(forKey: user.token)
            delegate?.user(dataSource: self, removed: user)
        }
    }
}
