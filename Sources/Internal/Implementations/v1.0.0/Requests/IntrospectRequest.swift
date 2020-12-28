//
//  IntrospectRequest.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient.APIVersion1.IntrospectRequest: IDXClientAPIRequest, ReceivesIDXResponse {
    typealias ResponseType = IDXClient.APIVersion1.Response
    
    init(interactionHandle: String) {
        requestBody = RequestBody(interactionHandle: interactionHandle)
    }
    
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest? {
        guard let url = configuration.issuerUrl(with: "idp/idx/introspect") else { return nil }

        let data: Data
        do {
            data = try JSONEncoder().encode(requestBody)
        } catch {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        httpHeaders.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }

        return request
    }
    
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
    {
        guard let request = urlRequest(using: configuration) else {
            completion(nil, IDXClientError.cannotCreateRequest)
            return
        }
        
        let task = session.dataTaskWithRequest(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            let response: ResponseType!
            do {
                response = try idxResponse(from: data)
            } catch {
                completion(nil, error)
                return
            }

            completion(response, nil)
        }
        task.resume()
    }
    
    struct RequestBody: Codable {
        let interactionHandle: String
    }
}
