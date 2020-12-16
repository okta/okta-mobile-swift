//
//  IDXClientAPIv1.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

extension IDXClient.APIVersion1: IDXClientAPIImpl {
    func interact(completion: @escaping(String?, Error?) -> Void) {
        let request = InteractRequest()
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            completion(response?.interactionHandle, nil)
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
                completion(nil, IDXClientAPIError.invalidResponseData)
                return
            }
            
            completion(IDXClient.Response(client: self, v1: response), nil)
        }
    }
    
    func identify(identifier: String,
                  credentials: IDXClient.Credentials,
                  rememberMe: Bool,
                  completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientAPIError.invalidClient)
            return
        }
        let request = IdentifyRequest(stateHandle: stateHandle,
                                      identifier: identifier,
                                      credentials: credentials,
                                      rememberMe: rememberMe)

    }
    
    func enroll(authenticator: IDXClient.Authenticator,
                completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientAPIError.invalidClient)
            return
        }
        let request = EnrollRequest(stateHandle: stateHandle,
                                    authenticator: authenticator)
        
    }
    
    func challenge(authenticator: IDXClient.Authenticator,
                   completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientAPIError.invalidClient)
            return
        }
        let request = ChallengeRequest(stateHandle: stateHandle,
                                       authenticator: authenticator)
        
    }
    
    func answerChallenge(credentials: IDXClient.Credentials,
                         completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientAPIError.invalidClient)
            return
        }
        let request = AnswerChallengeRequest(stateHandle: stateHandle,
                                             credentials: credentials)
        
    }
    
    func cancel(completion: @escaping (Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(IDXClientAPIError.invalidClient)
            return
        }
        let request = CancelRequest(stateHandle: stateHandle)

    }
    
    func token(url: String,
               grantType: String,
               interactionCode: String,
               completion: @escaping(IDXClient.Token?, Error?) -> Void)
    {
        let request = TokenRequest()

    }
    
    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any],
                 completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientAPIError.invalidClient)
            return
        }
        let request = RemediationRequest(stateHandle: stateHandle)
    }
}

extension IDXClient.Configuration {
    func issuerUrl(with path: String) -> URL? {
        return URL(string: issuer)?.appendingPathComponent(path)
    }
}

