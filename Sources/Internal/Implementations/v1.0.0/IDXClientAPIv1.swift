//
//  IDXClientAPIv1.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

extension IDXClient.APIVersion1: IDXClientAPIImpl {
    enum AcceptType: Equatable {
        private static let urlEncodedString = "application/x-www-form-urlencoded"
        private static let ionJsonString = "application/ion+json"
        
        case ionJson(version: String?)
        case formEncoded
        
        init?(rawValue: String) {
            if rawValue == AcceptType.urlEncodedString {
                self = .formEncoded
            } else if rawValue.hasPrefix(AcceptType.ionJsonString) {
                var version: String? = nil
                if let range = rawValue.range(of: "okta-version=") {
                    version = String(rawValue.suffix(from: range.upperBound))
                }
                self = .ionJson(version: version)
            } else {
                return nil
            }
        }
        
        public func stringValue() -> String {
            switch self {
            case .formEncoded:
                return AcceptType.urlEncodedString
            case .ionJson(version: let version):
                if version == nil {
                    return AcceptType.ionJsonString
                } else {
                    return "\(AcceptType.ionJsonString); okta-version=\(version!)"
                }
            }
        }
    }

    func interact(completion: @escaping(String?, Error?) -> Void) {
        let request = InteractRequest()
        request.send(to: session, using: configuration) { (response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let response = response {
                do {
                    try self.consumeResponse(response)
                } catch {
                    completion(nil, error)
                    return
                }
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
            
            if let response = response {
                do {
                    try self.consumeResponse(response)
                } catch {
                    completion(nil, error)
                    return
                }
            }

            guard let response = response else {
                completion(nil, IDXClientError.invalidResponseData)
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
            completion(nil, IDXClientError.stateHandleMissing)
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
            completion(nil, IDXClientError.stateHandleMissing)
            return
        }
        let request = EnrollRequest(stateHandle: stateHandle,
                                    authenticator: authenticator)
        
    }
    
    func challenge(authenticator: IDXClient.Authenticator,
                   completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientError.stateHandleMissing)
            return
        }
        let request = ChallengeRequest(stateHandle: stateHandle,
                                       authenticator: authenticator)
        
    }
    
    func answerChallenge(credentials: IDXClient.Credentials,
                         completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        guard let stateHandle = stateHandle else {
            completion(nil, IDXClientError.stateHandleMissing)
            return
        }
        let request = AnswerChallengeRequest(stateHandle: stateHandle,
                                             credentials: credentials)
        
    }
    
    func cancel(completion: @escaping (Error?) -> Void)
    {
        guard let cancelOption = cancelRemediationOption else {
            completion(IDXClientError.unknownRemediationOption(name: "cancel"))
            return
        }
        
        cancelOption.proceed(with: [:]) { (_, error) in
            completion(error)
        }
    }
    
    func token(url: String,
               grantType: String,
               interactionCode: String,
               completion: @escaping(IDXClient.Token?, Error?) -> Void)
    {
        let request = TokenRequest()

    }
    
    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any]? = nil,
                 completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        let request: RemediationRequest
        do {
            request = try RemediationRequest(remediation: option, parameters: data)
        } catch {
            completion(nil, IDXClientError.cannotCreateRequest)
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

            completion(IDXClient.Response(client: self, v1: response), nil)
        }
    }
}

extension IDXClient.APIVersion1 {
    func consumeResponse(_ response: InteractRequest.Response) throws {
        self.interactionHandle = response.interactionHandle
    }

    func consumeResponse(_ response: IntrospectRequest.ResponseType) throws {
        self.stateHandle = response.stateHandle
        self.cancelRemediationOption = IDXClient.Remediation.Option(client: self, v1: response.cancel)
    }
    
    func consumeResponse(_ response: IDXClient.Response) throws  {
        self.stateHandle = response.stateHandle
        self.cancelRemediationOption = response.cancelRemediationOption
    }
}

extension IDXClient.Configuration {
    func issuerUrl(with path: String) -> URL? {
        return URL(string: issuer)?.appendingPathComponent(path)
    }
}

