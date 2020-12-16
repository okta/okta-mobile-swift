//
//  RequestHTTPHeaders.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation

protocol HasHTTPHeaders {
    var httpHeaders: [String:String] { get }
}

protocol HasOAuthHTTPHeaders: HasHTTPHeaders {}
protocol HasIDPHTTPHeaders: HasHTTPHeaders {}

extension HasOAuthHTTPHeaders {
    var httpHeaders: [String : String] {
        get {
            return [
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json"
            ]
        }
    }
}

extension HasIDPHTTPHeaders {
    var httpHeaders: [String : String] {
        get {
            return [
                "Content-Type": "application/ion+json; okta-version=1.0.0",
                "Accept": "application/ion+json; okta-version=1.0.0"
            ]
        }
    }
}
