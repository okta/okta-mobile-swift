//
//  RemediationRequest.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient.APIVersion1.RemediationRequest: IDXClientAPIRequest, ReceivesIDXResponse {
    typealias ResponseType = IDXClient.APIVersion1.Response
    
    init(remediation option: IDXClient.Remediation.Option, parameters: [String:Any]) throws {
        guard let acceptType = IDXClient.APIVersion1.AcceptType(rawValue: option.accepts) else {
            throw IDXClientError.invalidRequestData
        }
        
        self.init(method: option.method,
                  href: option.href,
                  accepts: acceptType,
                  parameters: parameters)
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

        if let requestHasHeaders = self as? HasHTTPHeaders {
            requestHasHeaders.httpHeaders.forEach { (key, value) in
                request.addValue(value, forHTTPHeaderField: key)
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
            
            let result: ResponseType!
            do {
                result = try idxResponse(from: data)
            } catch {
                completion(nil, error)
                return
            }

            completion(result, nil)
        }
        task.resume()
    }
}
