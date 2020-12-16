//
//  Data+TestExtensions.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation

extension Data {
    func urlFormEncoded() -> [String:String?]? {
        guard let string = String(data: self, encoding: .utf8),
              let url = URL(string: "?\(string)"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return nil }

        return queryItems.reduce(into: [String:String?]()) {
            $0[$1.name] = $1.value
        }
    }
}

extension String {
    func isBase64URLEncoded() -> Bool {
        let charset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_").inverted
        return (rangeOfCharacter(from: charset) == nil)
    }
}
