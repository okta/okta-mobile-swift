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
import AuthFoundation

public protocol OAuth2Configuration {}

public enum OAuth2Error: Error {
    case invalidUrl
    case cannotComposeUrl
    case cannotGeneratePKCE
    case missingRequiredDelegate
    case invalidRedirect(message: String)
    case invalidState(_ state: String?)
    case oauth2Error(code: String, description: String?)
    case network(error: APIClientError)
    case flowNotReady(message: String)
    case missingResultCode
    case noResultReturned
    case error(_ error: Error)
}

public protocol OAuth2ClientDelegate: APIClientDelegate {
//    func oauth(client: Client<T>, customize url: inout URL, for endpoint: Client<T>.Endpoint)
}

public class OAuth2Client: APIClient {
    public let session: URLSession
    public let baseURL: URL
    public var additionalHttpHeaders: [String:String]? = nil
    
    convenience public init(domain: String, session: URLSession = URLSession.shared) throws {
        guard let url = URL(string: "https://\(domain)") else {
            throw OAuth2Error.invalidUrl
        }
        
        self.init(baseURL: url, session: session)
    }
    
    public init(baseURL: URL, session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func error(from data: Data) -> Error? {
        if let error = try? decode(OktaAPIError.self, from: data) {
            return error
        }
        
        if let error = try? decode(OAuth2ServerError.self, from: data) {
            return error
        }
        
        return nil
    }

    func received(_ response: APIResponse<Token>) {
        // Do something with the token
        print(response.result)
    }
    
    func exchange(token request: TokenRequest, completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }

    // MARK: Private properties / methods
    private let delegates = DelegateCollection<OAuth2ClientDelegate>()
}         

extension OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate
    public func add(delegate: Delegate) { delegates += delegate }
    public func remove(delegate: Delegate) { delegates -= delegate }
    
    public var delegateCollection: DelegateCollection<OAuth2ClientDelegate> {
        delegates
    }
}
