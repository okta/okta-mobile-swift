/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient.APIVersion1: IDXClientAPIImpl {
    enum AcceptType: Equatable {
        case json(version: String?)
        case ionJson(version: String?)
        case formEncoded
    }

    func interact(completion: @escaping(IDXClient.Context?, Error?) -> Void) {
        guard let codeVerifier = String.pkceCodeVerifier(),
              let codeChallenge = codeVerifier.pkceCodeChallenge() else
        {
            completion(nil, IDXClientError.internalError(message: "Cannot create a PKCE Code Verifier"))
            return
        }
        
        let request = InteractRequest(codeChallenge: codeChallenge)
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            self.interactionHandle = response.interactionHandle
            self.codeVerifier = codeVerifier
            
            completion(IDXClient.Context(interactionHandle: response.interactionHandle,
                                         codeVerifier: codeVerifier),
                       nil)
        }
    }
    
    func introspect(_ interactionHandle: String,
                    completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        let request = IntrospectRequest(interactionHandle: interactionHandle)
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
                try self.consumeResponse(response)
            } catch {
                completion(nil, error)
                return
            }

            completion(IDXClient.Response(api: self, v1: response), nil)
        }
    }
        
    var canCancel: Bool {
        return (cancelRemediationOption != nil)
    }
    
    func cancel(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        guard let cancelOption = cancelRemediationOption else {
            completion(nil, IDXClientError.unknownRemediationOption(name: "cancel"))
            return
        }
        
        cancelOption.proceed(with: [:]) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }

            do {
                try self.consumeResponse(response)
            } catch {
                completion(nil, error)
                return
            }

            completion(response, nil)
        }
    }
    
    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any],
                 completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        let request: RemediationRequest
        do {
            request = try RemediationRequest(remediation: option, parameters: data)
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
                try self.consumeResponse(response)
            } catch {
                completion(nil, error)
                return
            }

            completion(IDXClient.Response(api: self, v1: response), nil)
        }
    }

    func exchangeCode(using response: IDXClient.Response,
                      completion: @escaping (IDXClient.Token?, Error?) -> Void)
    {
        guard let successResponse = response.successResponse else {
            completion(nil, IDXClientError.successResponseMissing)
            return
        }

        let data: [String:Any] = successResponse.form
            .filter { $0.name != nil && $0.required && $0.value == nil }
            .reduce(into: [:]) { (result, formValue) in
                guard let name = formValue.name else { return }
                
                switch name {
                case "client_secret":
                    result[name] = configuration.clientSecret
                case "client_id":
                    result[name] = configuration.clientId
                case "code_verifier":
                    result[name] = self.codeVerifier
                default: break
                }
        }

        let request: TokenRequest
        do {
            request = try TokenRequest(successResponse: successResponse, parameters: data)
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
                try self.consumeResponse(response)
            } catch {
                completion(nil, error)
                return
            }

            completion(IDXClient.Token(api: self, v1: response), nil)
        }
    }
}

extension IDXClient.APIVersion1 {
    func consumeResponse(_ response: IntrospectRequest.ResponseType) throws {
        self.stateHandle = response.stateHandle
        self.cancelRemediationOption = IDXClient.Remediation.Option(api: self, v1: response.cancel)
    }
    
    func consumeResponse(_ response: IDXClient.Response) throws  {
        self.stateHandle = response.stateHandle
        self.cancelRemediationOption = response.cancelRemediationOption
    }

    func consumeResponse(_ response: TokenRequest.ResponseType) throws  {
        // Do nothing, for now
    }
}

extension IDXClient.Configuration {
    func issuerUrl(with path: String) -> URL? {
        return URL(string: issuer)?.appendingPathComponent(path)
    }
}
