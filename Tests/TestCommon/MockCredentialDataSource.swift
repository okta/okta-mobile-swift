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

class MockCredentialDataSource: CredentialDataSource {
    private(set) var credentials: [Credential] = []

    weak var delegate: CredentialDataSourceDelegate?

    var credentialCount: Int { credentials.count }
    
    func hasCredential(for token: Token) -> Bool {
        !credentials.filter({ $0.token == token }).isEmpty
    }

    func credential(for token: Token) -> Credential {
        if let credential = credentials.first(where: { $0.token == token }) {
            return credential
        } else {
            let urlSession = URLSessionMock()
            let client = OAuth2Client(baseURL: token.context.baseURL,
                                      session: urlSession)
            let credential = Credential(token: token, oauth2: client)
            credentials.append(credential)
            
            delegate?.credential(dataSource: self, created: credential)
            
            return credential
        }
    }
    
    func remove(credential: Credential) {
        guard let index = credentials.firstIndex(of: credential) else { return }
        credentials.remove(at: index)
        delegate?.credential(dataSource: self, removed: credential)
    }
}
