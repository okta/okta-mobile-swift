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

// TODO: Remove on the next major release.
extension WebAuthentication {
    @available(*, deprecated, renamed: "signIn(from:options:completion:)")
    public final func signIn(from window: WindowAnchor?,
                             additionalParameters: [String: String]?,
                             completion: @escaping (Result<Token, WebAuthenticationError>) -> Void)
    {
        signIn(from: window, options: options(from: additionalParameters), completion: completion)
    }

    @available(*, deprecated, renamed: "signOut(from:credential:options:completion:)")
    public final func signOut(from window: WindowAnchor? = nil,
                              credential: Credential? = .default,
                              additionalParameters: [String: String]?,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        signOut(from: window, credential: credential, options: options(from: additionalParameters), completion: completion)
    }
    
    @available(*, deprecated, renamed: "signOut(from:token:options:completion:)")
    public final func signOut(from window: WindowAnchor? = nil,
                              token: Token,
                              additionalParameters: [String: String]?,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        signOut(from: window, token: token, options: options(from: additionalParameters), completion: completion)
    }
    
    @available(*, deprecated, renamed: "signOut(from:token:options:completion:)")
    public final func signOut(from window: WindowAnchor? = nil,
                              token: String,
                              additionalParameters: [String: String]?,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        signOut(from: window, token: token, options: options(from: additionalParameters), completion: completion)
    }
    
    fileprivate func options(from additionalParameters: [String: String]?) -> [WebAuthentication.Option]? {
        return additionalParameters?.reduce(into: [WebAuthentication.Option]()) { (result, item) in
            switch item.key {
            case "login_hint":
                result.append(.login(hint: item.value))
            case "display":
                result.append(.display(item.value))
            case "idp":
                guard let url = URL(string: item.value) else { return }
                result.append(.idp(url: url))
            case "idp_scope":
                result.append(.idpScope(item.value))
            case "prompt":
                let prompt: WebAuthentication.Option.Prompt
                switch item.value {
                case "none":
                    prompt = .none
                case "consent":
                    prompt = .consent
                case "login":
                    prompt = .login
                case "login consent", "consent login":
                    prompt = .loginAndConsent
                default:
                    return
                }
                result.append(.prompt(prompt))
            case "max_age":
                let age: TimeInterval
                if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                    guard let value = try? TimeInterval(item.value, format: .number) else { return }
                    age = value
                } else {
                    guard let value = Double(item.value) else { return }
                    age = TimeInterval(value)
                }
                
                result.append(.maxAge(age))
            default:
                result.append(.custom(key: item.key, value: item.value))
            }
        }
    }
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension WebAuthentication {
    @available(*, deprecated, renamed: "signIn(from:options:)")
    public final func signIn(from window: WindowAnchor?,
                             additionalParameters: [String: String]?) async throws -> Token
    {
        try await signIn(from: window, options: options(from: additionalParameters))
    }
    
    @available(*, deprecated, renamed: "signOut(from:credential:options:)")
    public final func signOut(from window: WindowAnchor?,
                              credential: Credential? = .default,
                              additionalParameters: [String: String]?) async throws
    {
        try await signOut(from: window, credential: credential, options: options(from: additionalParameters))
    }
    
    @available(*, deprecated, renamed: "signOut(from:token:options:)")
    public final func signOut(from window: WindowAnchor?,
                              token: Token,
                              additionalParameters: [String: String]?) async throws
    {
        try await signOut(from: window, token: token, options: options(from: additionalParameters))
    }
    
    @available(*, deprecated, renamed: "signOut(from:token:options:)")
    public final func signOut(from window: WindowAnchor?,
                              token: String,
                              additionalParameters: [String: String]?) async throws
    {
        try await signOut(from: window, token: token, options: options(from: additionalParameters))
    }
}
#endif
