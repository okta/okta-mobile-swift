//
//  TokenRequest.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient.APIVersion1.TokenRequest: IDXClientAPIRequest {
    typealias ResponseType = IDXClient.APIVersion1.Token
    
    init(successResponse option: IDXClient.Remediation.Option, parameters: [String:Any]? = nil) throws {
        guard let acceptType = IDXClient.APIVersion1.AcceptType(rawValue: option.accepts) else {
            throw IDXClientError.invalidRequestData
        }
        
        self.init(method: option.method,
                  href: option.href,
                  accepts: acceptType,
                  parameters: try option.formValues(with: parameters))
    }
    
    func urlRequest(using configuration: IDXClient.Configuration) -> URLRequest? {
        let data: Data?
        do {
            data = try accepts.encodedData(with: parameters)
        } catch {
            return nil
        }

        var request = URLRequest(url: href)
        request.httpMethod = method
        request.httpBody = data
        request.addValue(accepts.stringValue(), forHTTPHeaderField: "Content-Type")
        httpHeaders.forEach { (key, value) in
            if request.allHTTPHeaderFields?[key] == nil {
                request.setValue(value, forHTTPHeaderField: key)
            }
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
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let response: ResponseType!
            do {
                response = try decoder.decode(ResponseType.self, from: data)
            } catch {
                completion(nil, error)
                return
            }

            completion(response, nil)
        }
        task.resume()
    }
}
