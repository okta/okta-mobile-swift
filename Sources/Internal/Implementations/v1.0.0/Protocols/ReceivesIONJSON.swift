//
//  ReceivesIONJSON.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-14.
//

import Foundation

protocol ReceivesIDXResponse {
    func idxResponse(from data: Data) throws -> IDXClient.APIVersion1.Response
}

extension DateFormatter {
    static let idxDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension JSONDecoder {
    static let idxResponseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.idxDateFormatter)
        return decoder
    }()
}

extension ReceivesIDXResponse {
    func idxResponse(from data: Data) throws -> IDXClient.APIVersion1.Response {
        return try JSONDecoder.idxResponseDecoder.decode(IDXClient.APIVersion1.Response.self, from: data)
    }
}
