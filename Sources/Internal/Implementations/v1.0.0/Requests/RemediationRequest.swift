//
//  RemediationRequest.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient.APIVersion1.RemediationRequest: IDXClientAPIRequest {
    typealias ResponseType = Decodable

    func urlRequest(using configuration: IDXClient.Configuration) -> URLRequest? {
        return nil
    }

    func send(to session: URLSessionProtocol, using configuration: IDXClient.Configuration, completion: @escaping (ResponseType?, Error?) -> Void) {
    }
    
}
