//
//  AcceptType.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-28.
//

import Foundation

extension IDXClient.APIVersion1.AcceptType {
    func encodedData(with parameters: [String:Any]) throws -> Data?{
        switch self {
        case .formEncoded:
            guard let parameters = parameters as? [String:String] else {
                throw IDXClientError.invalidRequestData
            }
            return URLRequest.idxURLFormEncodedString(for: parameters)?.data(using: .utf8)
            
        case .ionJson:
            return try JSONSerialization.data(withJSONObject: parameters, options: .sortedKeys)
        }
    }
}
