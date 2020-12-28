//
//  InteractRequest.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

extension IDXClient.APIVersion1.InteractRequest: IDXClientAPIRequest {
    static let challengeMethod = "S256"
    
    typealias ResponseType = Response
    
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest? {
        guard let url = configuration.issuerUrl(with: "v1/interact") else { return nil }

        guard let codeVerifier = String.pkceCodeVerifier(),
              let codeChallenge = codeVerifier.pkceCodeChallenge() else
        {
            return nil
        }
        
        configuration.codeVerifier = codeVerifier

        let params = [
            "client_id": configuration.clientId,
            "scope": configuration.scopes.joined(separator: " "),
            "code_challenge": codeChallenge,
            "code_challenge_method": "S256",
            "redirect_uri": configuration.redirectUri,
            "state": UUID().uuidString
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = URLRequest.idxURLFormEncodedString(for: params)?.data(using: .utf8)
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
    
    struct Response: Codable {
        let interactionHandle: String
    }
}
