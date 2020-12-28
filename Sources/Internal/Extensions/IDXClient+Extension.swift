//
//  IDXClient+Extension.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient {
    internal class APIVersion1 {
        static let version = Version.v1_0_0
        var stateHandle: String? = nil
        var interactionHandle: String? = nil
        var cancelRemediationOption: IDXClient.Remediation.Option? = nil
        
        let queue: DispatchQueue
        let configuration: IDXClient.Configuration
        let session: URLSessionProtocol
        weak var delegate: IDXClientAPIDelegate?

        init(with configuration: Configuration, queue: DispatchQueue? = nil, session: URLSessionProtocol? = nil) {
            self.configuration = configuration
            
            self.queue = queue ?? DispatchQueue(label: "com.okta.idx.v1",
                                                qos: .userInteractive,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem,
                                                target: nil)
            self.session = session ?? URLSession(configuration: URLSessionConfiguration.ephemeral)
        }
    }
    
    public func interact(completion: @escaping(String?, Error?) -> Void) {
        self.api.interact(completion: completion)
    }
    
    public func introspect(_ interactionHandle: String,
                           completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.introspect(interactionHandle, completion: completion)
    }
    
    public func identify(identifier: String,
                         credentials: IDXClient.Credentials,
                         rememberMe: Bool,
                         completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.identify(identifier: identifier, credentials: credentials, rememberMe: rememberMe, completion: completion)
    }
    
    public func enroll(authenticator: IDXClient.Authenticator,
                       completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.enroll(authenticator: authenticator, completion: completion)
    }
    
    public func challenge(authenticator: IDXClient.Authenticator,
                          completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.challenge(authenticator: authenticator, completion: completion)
    }
    
    public func answerChallenge(credentials: IDXClient.Credentials,
                                completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.answerChallenge(credentials: credentials, completion: completion)
    }
    
    public func cancel(completion: @escaping (Error?) -> Void)
    {
        self.api.cancel(completion: completion)
    }
    
    public func token(url: String,
                      grantType: String,
                      interactionCode: String,
                      completion: @escaping(IDXClient.Token?, Error?) -> Void)
    {
        self.api.token(url: url, grantType: grantType, interactionCode: interactionCode, completion: completion)
    }
}

extension IDXClient: IDXClientAPIDelegate {
    func clientAPIStateHandleChanged(stateHandle: String?) {
        print("State handle changed to \(stateHandle)")
    }
}

