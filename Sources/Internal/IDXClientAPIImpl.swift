//
//  IDXClientAPIImpl.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation

/// Internal protocol used to implement the IDXClientAPI protocol.
internal protocol IDXClientAPIImpl: class, IDXClientAPI {
    /// The client version for this API implementation.
    static var version: IDXClient.Version { get }
    
    /// The client configuration used when constructing the API implementation.
    var configuration: IDXClient.Configuration { get }
    
    /// The delegate used to coordinate messages to the public-facing client API instance.
    var delegate: IDXClientAPIDelegate? { get set }
}

/// Delegate protocol used to receive messages and updates from IDXClientAPIImpl instances.
internal protocol IDXClientAPIDelegate: class {
    func clientAPIStateHandleChanged(stateHandle: String?)
}

/// Protocol used to represent IDX API requests, and their expected response types.
internal protocol IDXClientAPIRequest {
    associatedtype ResponseType
    /// Produces a URLRequest suitable for performing the request.
    /// - Parameter configuration: Client configuration.
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest?
    
    /// Sends the request to the given URL session, returning the response asynchronously to the supplied completion block.
    /// - Parameters:
    ///   - session: URL session to send the network request on.
    ///   - configuration: Client configuration.
    ///   - completion: Completion handler to receive the response.
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
}
