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
    
    public func start(completion: @escaping (Response?, Error?) -> Void) {
        self.api.start(completion: completion)
    }
    
    public func cancel(completion: @escaping (Error?) -> Void)
    {
        self.api.cancel(completion: completion)
    }
    
    public func proceed(remediation option: Remediation.Option,
                        data: [String : Any]? = nil,
                        completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.proceed(remediation: option, data: data, completion: completion)
    }
    
    public func exchangeCode(using successResponse: Remediation.Option, completion: @escaping (Token?, Error?) -> Void) {
        self.api.exchangeCode(using: successResponse, completion: completion)
    }
}

extension IDXClient: IDXClientAPIDelegate {
    func clientAPIStateHandleChanged(stateHandle: String?) {
        print("State handle changed to \(stateHandle)")
    }
}

