/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension IDXClient {
    internal class APIVersion1 {
        static let version = Version.v1_0_0
        weak var client: IDXClientAPI?
        
        let configuration: IDXClient.Configuration
        let session: URLSessionProtocol

        init(with configuration: Configuration, session: URLSessionProtocol? = nil) {
            self.configuration = configuration
            self.session = session ?? URLSession(configuration: URLSessionConfiguration.ephemeral)
        }

        internal enum AcceptType: Equatable {
            case json(version: String?)
            case ionJson(version: String?)
            case formEncoded
        }
    }
}

extension IDXClient.APIVersion1: IDXClientAPIImpl {
    func start(state: String?, completion: @escaping (IDXClient.Context?, Error?) -> Void) {
        guard let codeVerifier = String.pkceCodeVerifier(),
              let codeChallenge = codeVerifier.pkceCodeChallenge() else
        {
            completion(nil, IDXClientError.internalError(message: "Cannot create a PKCE Code Verifier"))
            return
        }
        
        let request = InteractRequest(state: state, codeChallenge: codeChallenge)
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            completion(IDXClient.Context(configuration: self.configuration,
                                         state: request.state,
                                         interactionHandle: response.interactionHandle,
                                         codeVerifier: codeVerifier),
                       nil)
        }
    }
    
    func resume(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        guard let client = client else {
            completion(nil, IDXClientError.invalidClient)
            return
        }
        
        let request = IntrospectRequest(interactionHandle: client.context.interactionHandle)
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            do {
                completion(try IDXClient.Response(client: client, v1: response), nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    func proceed(remediation option: IDXClient.Remediation,
                 completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let client = client else {
            completion(nil, IDXClientError.invalidClient)
            return
        }

        let request: RemediationRequest
        do {
            request = try RemediationRequest(remediation: option)
        } catch {
            completion(nil, error)
            return
        }

        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            do {
                completion(try IDXClient.Response(client: client, v1: response), nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult {
        guard let context = client?.context else {
            return .invalidContext
        }

        guard let redirect = Redirect(url: url),
              let originalRedirect = Redirect(url: configuration.redirectUri) else
        {
            return .invalidRedirectUrl
        }
        
        guard originalRedirect.scheme == redirect.scheme &&
                originalRedirect.path == redirect.path else
        {
            return .invalidRedirectUrl
        }
        
        if context.state != redirect.state {
            return .invalidContext
        }
        
        if redirect.interactionCode != nil {
            return .authenticated
        }
        
        if redirect.interactionRequired {
            return .remediationRequired
        }
        
        return .invalidContext
    }
    
    func exchangeCode(redirect url: URL, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        guard let context = client?.context else {
            completion(nil, IDXClientError.invalidClient)
            return
        }
        
        guard let redirect = Redirect(url: url) else {
            completion(nil, IDXClientError.internalError(message: "Invalid redirect url"))
            return
        }
        
        guard let issuerUrl = URL(string: configuration.issuer) else {
            completion(nil, IDXClientError.internalError(message: "Cannot create URL from issuer"))
            return
        }
        
        guard let interactionCode = redirect.interactionCode else {
            completion(nil, IDXClientError.internalError(message: "Interaction code is missed"))
            return
        }
        
        let request = TokenRequest(issuer: issuerUrl,
                                   clientId: configuration.clientId,
                                   clientSecret: configuration.clientSecret,
                                   codeVerifier: context.codeVerifier,
                                   grantType: "interaction_code",
                                   code: interactionCode)

        send(request, completion)
    }

    func exchangeCode(using remediation: IDXClient.Remediation, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        guard let context = client?.context else {
            completion(nil, IDXClientError.invalidClient)
            return
        }
        
        guard remediation.name == "issue" else {
            completion(nil, IDXClientError.successResponseMissing)
            return
        }

        remediation.form["client_id"]?.value = configuration.clientId
        remediation.form["client_secret"]?.value = configuration.clientSecret
        remediation.form["code_verifier"]?.value = context.codeVerifier

        let request: TokenRequest
        do {
            request = try TokenRequest(successResponse: remediation)
        } catch {
            completion(nil, error)
            return
        }
        
        send(request, completion)
    }
    
    func revoke(token: String, type: String, completion: @escaping (Bool, Error?) -> Void) {
        let request = RevokeRequest(token: token, tokenTypeHint: type)
        request.send(to: session,
                     using: configuration) { (response, error) in
            completion(response ?? false, error)
        }
    }
    
    func refresh(token: IDXClient.Token,
                 completion: @escaping(_ token: IDXClient.Token?, _ error: Error?) -> Void)
    {
        guard let url = token.configuration.issuerUrl(with: "v1/token") else {
            completion(nil, IDXClientError.invalidClient)
            return
        }
        
        guard let refreshToken = token.refreshToken else {
            completion(nil, IDXClientError.missingRefreshToken)
            return
        }
        
        var parameters = [
            "grant_type": "refresh_token",
            "scope": configuration.scopes.joined(separator: " "),
            "redirect_uri": configuration.redirectUri,
            "client_id": configuration.clientId,
            "refresh_token": refreshToken,
            "authorization": token.accessToken
        ]
        
        if let clientSecret = configuration.clientSecret {
            parameters["client_secret"] = clientSecret
        }
        
        let request = TokenRequest(method: "POST",
                                   href: url,
                                   accepts: .formEncoded,
                                   parameters: parameters)
        request.send(to: session,
                     using: configuration) { (response, error) in
            guard let response = response else {
                completion(nil, error)
                return
            }
            completion(IDXClient.Token(v1: response, configuration: self.configuration), nil)
        }
    }

    private func send(_ request: IDXClient.APIVersion1.TokenRequest, _ completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            completion(IDXClient.Token(v1: response, configuration: self.configuration), nil)
        }
    }
}

extension IDXClient.Configuration {
    func issuerUrl(with path: String) -> URL? {
        return URL(string: issuer)?.appendingPathComponent(path)
    }
}
