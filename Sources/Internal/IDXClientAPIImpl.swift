//
//  IDXClientAPIImpl.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation

internal protocol IDXClientAPIImpl: class, IDXClientAPI {
    static var version: IDXClient.Version { get }
    var configuration: IDXClient.Configuration { get }
    var delegate: IDXClientAPIDelegate? { get set }
}

internal protocol IDXClientAPIDelegate: class {
    func clientAPIStateHandleChanged(stateHandle: String?)
}

internal protocol IDXClientAPIRequest {
    associatedtype ResponseType
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest?
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
}
